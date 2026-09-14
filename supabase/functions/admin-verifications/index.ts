// supabase/functions/admin-verifications/index.ts
//
// Called by the Flutter app (once an admin screen exists):
//   functions.invoke('admin-verifications', body: {action: 'list'})
//   functions.invoke('admin-verifications', body: {action: 'review', id, decision: 'approve'|'reject'})
//
// Requires the caller's profiles.role = 'admin'. verify_jwt stays true —
// Supabase's gateway already rejects unsigned-in callers before this runs;
// the role check below additionally rejects signed-in non-admins.

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
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const token = req.headers.get("Authorization")?.replace("Bearer ", "");
    if (!token) return json({ error: "missing bearer token" }, 401);

    const { data: userData, error: userError } = await supabaseAdmin.auth.getUser(token);
    if (userError || !userData.user) return json({ error: "invalid or expired token" }, 401);

    const { data: profile } = await supabaseAdmin
      .from("profiles")
      .select("role")
      .eq("id", userData.user.id)
      .maybeSingle();
    if (profile?.role !== "admin") return json({ error: "admin role required" }, 403);

    const body = await req.json();

    if (body?.action === "list") {
      const status = body.status ?? "pending";
      const { data, error } = await supabaseAdmin
        .from("rider_verifications")
        .select("*, profiles!rider_verifications_rider_id_fkey(full_name, phone_number)")
        .eq("status", status)
        .order("submitted_at", { ascending: true });
      if (error) return json({ error: error.message }, 500);
      return json({ verifications: data });
    }

    if (body?.action === "review") {
      const id = body.id as string | undefined;
      const decision = body.decision as "approve" | "reject" | undefined;
      if (!id || (decision !== "approve" && decision !== "reject")) {
        return json({ error: "expected { action: 'review', id, decision: 'approve'|'reject' }" }, 400);
      }
      const { data, error } = await supabaseAdmin
        .from("rider_verifications")
        .update({
          status: decision === "approve" ? "approved" : "rejected",
          reviewed_at: new Date().toISOString(),
          reviewed_by: userData.user.id,
        })
        .eq("id", id)
        .select()
        .maybeSingle();
      if (error) return json({ error: error.message }, 500);
      if (!data) return json({ error: "verification not found" }, 404);
      return json({ ok: true, verification: data });
    }

    return json({ error: "expected { action: 'list' | 'review', ... }" }, 400);
  } catch (e) {
    console.error("admin-verifications error:", e);
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}
