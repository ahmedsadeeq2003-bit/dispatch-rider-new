// supabase/functions/admin-companies/index.ts
//
// Called by the Flutter app (once an admin screen exists):
//   functions.invoke('admin-companies', body: {action: 'list'})
//   functions.invoke('admin-companies', body: {action: 'create', code, name, plan})
//
// Requires the caller's profiles.role = 'admin'.

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
      const { data, error } = await supabaseAdmin
        .from("companies")
        .select()
        .order("created_at", { ascending: false });
      if (error) return json({ error: error.message }, 500);
      return json({ companies: data });
    }

    if (body?.action === "create") {
      const code = body.code as string | undefined;
      const name = body.name as string | undefined;
      const plan = (body.plan as string | undefined) ?? "free";
      if (!code || code.length < 2 || !name) {
        return json({ error: "expected { action: 'create', code, name, plan? }" }, 400);
      }
      const { data, error } = await supabaseAdmin
        .from("companies")
        .insert({ code, name, plan })
        .select()
        .single();
      if (error) return json({ error: error.message }, 400);
      return json({ company: data }, 201);
    }

    return json({ error: "expected { action: 'list' | 'create', ... }" }, 400);
  } catch (e) {
    console.error("admin-companies error:", e);
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}
