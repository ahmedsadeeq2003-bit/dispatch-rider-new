// supabase/functions/deliveries-webhook/index.ts
//
// Target for a Supabase Database Webhook on the `deliveries` table
// (INSERT + UPDATE). Replaces the Render-hosted /hooks/deliveries endpoint —
// runs on Supabase's own infra, zero extra hosting cost.
//
// Wiring (one-time, Dashboard only, no secrets to copy):
//   Database -> Webhooks -> Create a new hook
//     Table: deliveries | Events: Insert, Update
//     Type: Supabase Edge Functions -> select "deliveries-webhook"
//   Supabase signs the request with the project's service_role key
//   automatically when you pick "Supabase Edge Functions" as the type, which
//   is why this function can keep verify_jwt = true (the default/safe
//   setting) instead of needing a hand-rolled shared secret.
//
// Requires the FCM_PROJECT_ID and FCM_SERVICE_ACCOUNT_JSON secrets to be set
// (`supabase secrets set ...` or Dashboard -> Edge Functions -> Secrets) —
// see supabase/functions/README.md. SUPABASE_URL and
// SUPABASE_SERVICE_ROLE_KEY are injected automatically by Supabase, no setup
// needed for those.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

// ---------------------------------------------------------------------------
// FCM HTTP v1, signed with the service account's private key via Web Crypto
// (no npm/Firebase Admin SDK dependency needed on Deno).
// ---------------------------------------------------------------------------
function base64url(input: Uint8Array | string): string {
  const bytes = typeof input === "string" ? new TextEncoder().encode(input) : input;
  let str = "";
  bytes.forEach((b) => (str += String.fromCharCode(b)));
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function getFcmAccessToken(): Promise<string> {
  const serviceAccount = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")!);
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const signingInput = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claim))}`;

  const pem = (serviceAccount.private_key as string)
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );
  const jwt = `${signingInput}.${base64url(new Uint8Array(signature))}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const tokenJson = await tokenRes.json();
  if (!tokenRes.ok) throw new Error(`FCM token exchange failed: ${JSON.stringify(tokenJson)}`);
  return tokenJson.access_token as string;
}

async function sendPush(
  accessToken: string,
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>,
) {
  const projectId = Deno.env.get("FCM_PROJECT_ID")!;
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ message: { token, notification: { title, body }, data } }),
    },
  );
  if (!res.ok) {
    console.error(`FCM send failed (${res.status}) for ${token.slice(0, 12)}…: ${await res.text()}`);
  }
}

async function sendPushToMany(
  tokens: string[],
  title: string,
  body: string,
  data?: Record<string, string>,
) {
  const clean = tokens.filter((t) => !!t);
  if (clean.length === 0) return;
  const accessToken = await getFcmAccessToken();
  await Promise.all(clean.map((t) => sendPush(accessToken, t, title, body, data)));
}

// ---------------------------------------------------------------------------
// Webhook handler
// ---------------------------------------------------------------------------
interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: Record<string, unknown> | null;
  old_record: Record<string, unknown> | null;
}

Deno.serve(async (req: Request) => {
  try {
    const payload = (await req.json()) as WebhookPayload;
    const record = payload.record as any;
    if (!record) return json({ ok: true });

    if (payload.type === "INSERT" && record.status === "pending") {
      await notifyNearbyRiders(record.id, record.pickup_address, record.dropoff_address);
    } else if (
      payload.type === "UPDATE" &&
      record.status === "accepted" &&
      (payload.old_record as any)?.status === "pending"
    ) {
      await notifyClientAccepted(record.id);
    }

    return json({ ok: true });
  } catch (e) {
    console.error("deliveries-webhook error:", e);
    // 200 even on failure — a push failure shouldn't look like a delivery
    // failure to whatever is watching the webhook's own delivery log.
    return json({ ok: false, error: String(e) });
  }
});

function json(body: unknown) {
  return new Response(JSON.stringify(body), {
    headers: { "Content-Type": "application/json" },
  });
}

async function notifyNearbyRiders(deliveryId: string, pickup: string, destination: string) {
  const { data: riders, error } = await supabaseAdmin.rpc("find_nearby_riders", {
    p_delivery_id: deliveryId,
    p_radius_m: 15000,
    p_limit: 5,
  });
  if (error) throw error;

  const tokens = (riders ?? [])
    .map((r: { fcm_token: string | null }) => r.fcm_token)
    .filter((t: string | null): t is string => !!t);

  if (tokens.length === 0) {
    console.log(`No online riders with a location in range for delivery ${deliveryId}`);
    return;
  }

  await sendPushToMany(
    tokens,
    "New Delivery Request!",
    `Pickup: ${pickup}\nDestination: ${destination}`,
    { type: "new_delivery", deliveryId },
  );
}

async function notifyClientAccepted(deliveryId: string) {
  const { data, error } = await supabaseAdmin
    .rpc("get_delivery_notify_targets", { p_delivery_id: deliveryId })
    .maybeSingle();
  if (error) throw error;
  const clientToken = (data as { client_token: string | null } | null)?.client_token;
  if (!clientToken) return;

  await sendPushToMany(
    [clientToken],
    "Rider found!",
    "A rider has accepted your delivery request.",
    { type: "delivery_accepted", deliveryId },
  );
}
