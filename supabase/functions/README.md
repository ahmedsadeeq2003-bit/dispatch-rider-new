# Supabase Edge Functions — dispatch-rider

**All server-side logic runs here — no separate hosting account, no Render, no extra bill.**
Edge Functions run on Supabase's own infra as part of the project already created (see
[`../README.md`](../README.md)); the free tier (500K invocations/month) covers an MVP many times
over. This replaced an earlier Render-based Node/Express design — see the "why not Render"
note at the bottom.

All 4 functions below are **deployed and ACTIVE** on project `bvztrnekmjaulwsjymcc` as of
2026-09-13.

| Function | Invoked by | Auth | Does |
|---|---|---|---|
| `deliveries-webhook` | a Supabase Database Webhook on `deliveries` (INSERT/UPDATE) | Supabase-signed (see wiring below) | real FCM push fan-out to nearby riders on a new `pending` delivery; pushes the client when accepted |
| `submit-rating` | Flutter: `supabase.functions.invoke('submit-rating', body: {...})` | end-user JWT | client rates the rider of their own completed, unrated delivery — the only caller of `apply_rider_rating()` |
| `admin-verifications` | Flutter (once an admin screen exists) | end-user JWT, `role=admin` | list / approve / reject rider verifications |
| `admin-companies` | Flutter (once an admin screen exists) | end-user JWT, `role=admin` | list / create companies + invite codes |

## Wiring the Database Webhook (one-time, Dashboard only, zero secrets to copy)

Supabase Dashboard → **Database → Webhooks → Create a new hook**:
- **Table:** `deliveries`
- **Events:** Insert, Update
- **Type:** **Supabase Edge Functions** → select `deliveries-webhook`

Picking "Supabase Edge Functions" as the type makes Supabase sign the request with the
project's own `service_role` key automatically — that's why `deliveries-webhook` can keep
`verify_jwt = true` (the safe default) instead of needing a hand-rolled shared secret header.
Nobody has to copy a key anywhere for this step.

## The one unavoidable manual step: FCM credentials

Push requires a **Google/Firebase credential** no matter where the code runs — this isn't a
hosting requirement, Supabase can't generate it for you. Only `deliveries-webhook` needs it:

1. Firebase Console → Project Settings → Service Accounts (project `dispatch-rider-2fb16-b28e7`)
   → **Generate new private key** for a service account scoped to Cloud Messaging only. (Or:
   Google Cloud Console → IAM → Service Accounts → Create → grant only **Firebase Cloud
   Messaging API Admin**.) **Do not reuse** the old Firestore admin-sdk key flagged in
   `FORENSIC_AUDIT.md` — that one should already be rotated/deleted.
2. Set two Edge Function secrets (Dashboard → Edge Functions → Manage secrets, or
   `supabase secrets set` with the CLI if you have it installed locally):
   ```
   FCM_PROJECT_ID=dispatch-rider-2fb16-b28e7
   FCM_SERVICE_ACCOUNT_JSON=<paste the entire downloaded JSON file as one line>
   ```
`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` do **not** need to be set — Supabase injects
those into every Edge Function automatically.

## Redeploying after an edit

Whoever has Supabase CLI access can redeploy with `supabase functions deploy <name>` from this
`supabase/` directory (needs `supabase login` + `supabase link`). Claude can also redeploy
directly through the Supabase MCP connection without any local CLI setup.

## Why not Render (or any external host)?

The original Phase 1 design proposed an external Node/Express service on Render specifically
because at the time push fan-out, rider matching, rating, and admin actions all needed
*somewhere* to run server-side with elevated (`service_role`) privileges. Supabase Edge
Functions satisfy that exact requirement — server-side code with `service_role` access — without
a second hosting account, a second bill, or a second thing to keep deployed. There is currently
no requirement in this app that Edge Functions can't handle: no long-running background jobs, no
non-HTTP protocols, no compute Deno can't do. If one shows up later (e.g. a heavy scheduled batch
job, a stateful websocket server), that's the trigger to reconsider an external service — not
before.
