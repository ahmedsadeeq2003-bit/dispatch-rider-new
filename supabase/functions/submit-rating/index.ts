// supabase/functions/submit-rating/index.ts
//
// Called by the Flutter app: Supabase.instance.client.functions.invoke(
//   'submit-rating', body: {deliveryId, stars})
//
// A client rates the rider of their own completed, not-yet-rated delivery.
// This is the only caller of apply_rider_rating() — that RPC is
// service_role-only precisely so this function can enforce "only the client
// of a COMPLETED, unrated delivery may rate, and only once" first.
//
// verify_jwt stays true (default): Supabase's gateway rejects the call
// before it even reaches this code if the caller isn't signed in.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    const token = authHeader?.replace("Bearer ", "");
    if (!token) return json({ error: "missing bearer token" }, 401);

    const { data: userData, error: userError } = await supabaseAdmin.auth.getUser(token);
    if (userError || !userData.user) return json({ error: "invalid or expired token" }, 401);
    const userId = userData.user.id;

    const body = await req.json();
    const deliveryId = body?.deliveryId as string | undefined;
    const stars = Number(body?.stars);
    if (!deliveryId || !Number.isFinite(stars) || stars < 1 || stars > 5) {
      return json({ error: "expected { deliveryId: string, stars: 1-5 }" }, 400);
    }

    const { data: delivery, error: fetchError } = await supabaseAdmin
      .from("deliveries")
      .select("id, client_id, rider_id, status, rating_submitted")
      .eq("id", deliveryId)
      .maybeSingle();

    if (fetchError) return json({ error: fetchError.message }, 500);
    if (!delivery) return json({ error: "delivery not found" }, 404);
    if (delivery.client_id !== userId) {
      return json({ error: "only the client of this delivery may rate it" }, 403);
    }
    if (delivery.status !== "completed") {
      return json({ error: "delivery is not completed yet" }, 409);
    }
    if (delivery.rating_submitted) {
      return json({ error: "this delivery has already been rated" }, 409);
    }
    if (!delivery.rider_id) {
      return json({ error: "delivery has no assigned rider" }, 409);
    }

    const { error: rpcError } = await supabaseAdmin.rpc("apply_rider_rating", {
      p_rider: delivery.rider_id,
      p_stars: stars,
    });
    if (rpcError) return json({ error: rpcError.message }, 500);

    const { error: markError } = await supabaseAdmin
      .from("deliveries")
      .update({ rating_submitted: true })
      .eq("id", deliveryId);
    if (markError) return json({ error: markError.message }, 500);

    return json({ ok: true });
  } catch (e) {
    console.error("submit-rating error:", e);
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}
