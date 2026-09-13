# Supabase project — dispatch-rider

**Project ref:** `bvztrnekmjaulwsjymcc` · **Region:** eu-west-2 (London) · **Org:** `ciqhryhdhpldojfgaacm`
**URL:** `https://bvztrnekmjaulwsjymcc.supabase.co`
**Client key:** publishable key `sb_publishable_S1BLCHQoCkUvgjA51Mobgg_ItG6-1sn` (embedded in
`lib/supabase_config.dart` — safe to ship client-side, protected by RLS not secrecy)

Created 2026-09-13 as part of the Firebase → Supabase migration (see
[`MIGRATION_PHASE1_DESIGN.md`](../MIGRATION_PHASE1_DESIGN.md) and
[`FORENSIC_AUDIT.md`](../FORENSIC_AUDIT.md) at the repo root).

## Migrations (applied, in order)

| # | File | What it does |
|---|---|---|
| 0001 | `0001_schema.sql` | Extensions (pgcrypto, postgis), enums, `companies`/`profiles`/`rider_verifications`/`deliveries`/`delivery_locations` tables, indexes, triggers (`handle_new_user`, `set_updated_at`), RPCs (`current_company_id`, `current_role`, `join_company`, `apply_rider_rating`), realtime publication |
| 0002 | `0002_policies.sql` | RLS on every table + `rider-verification` Storage bucket & policies |
| 0003 | `0003_transitions_and_admin.sql` | Delivery state-machine trigger + in-app admin RLS |
| 0004 | `0004_security_hardening.sql` | Post-`get_advisors` fixes: `search_path` on trigger functions, revoked public/anon execute on trigger functions and `apply_rider_rating` (service_role only), `join_company` restricted to authenticated |
| 0005 | `0005_default_company.sql` | Seeds a `DEFAULT` company and makes `handle_new_user()` fall back to it — the redesigned UI has no company-code field, but the schema stays multi-tenant-ready |
| 0006 | `0006_rider_verifications_match_ui.sql` | Reshapes `rider_verifications` to match the actual redesigned form (proof-of-address text + next-of-kin fields + one document image, not the original proof/selfie image pair) |
| 0007 | `0007_allow_direct_completion.sql` | Widens the state machine so `accepted → completed` is legal directly (the app's "Complete" button skips `picked_up`/`in_transit`, which exist only as display labels today) |
| 0008 | `0008_backend_support.sql` | `find_nearby_riders()` + `get_delivery_notify_targets()` RPCs (service_role-only) and `deliveries.rating_submitted` column, for the Edge Functions in `functions/` |

Apply order matters — run them in numeric order against a fresh project.

## Server-side logic: Edge Functions, not an external backend

**No Render, no separate hosting account, no extra bill.** All server-side logic (push
fan-out, rider matching, rating submission, admin actions) runs as Supabase Edge Functions —
see [`functions/README.md`](functions/README.md). An earlier design used a Render-hosted
Node/Express service; it's been replaced entirely because Edge Functions already provide
everything that design needed (server-side code with `service_role` access, triggered by a
Database Webhook or called directly from the app) at zero extra cost.

## Known, accepted advisor findings (see 0004's trailing comment block)

- `public.spatial_ref_sys` has RLS disabled — this is a PostGIS system table (public EPSG
  reference data, no user data). Enabling RLS requires an explicit allow-all-read policy;
  not applied without a human decision (Supabase's own advisor guidance).
- `postgis` extension lives in the `public` schema, not `extensions` — PostGIS doesn't support
  `ALTER EXTENSION ... SET SCHEMA`; fixing requires a drop/recreate (safe now, 0 rows, but
  deferred as a schema-shape change rather than pure hardening).
- `st_estimatedextent(...)` executable by anon/authenticated — stock PostGIS built-in, not
  something this project defined.
- `current_company_id()`, `current_role()`, `join_company()` still SECURITY DEFINER +
  authenticated-executable — intentional, self-service helpers scoped to `auth.uid()`.

## What's NOT built yet (tracked in MIGRATION_PHASE1_DESIGN.md)

- ~~Backend service~~ — **done, deployed, Supabase-only.** 4 Edge Functions are live
  (`deliveries-webhook`, `submit-rating`, `admin-verifications`, `admin-companies` — see
  `functions/README.md`). Only two things remain, both one-time and neither is a hosting cost:
  wiring the Database Webhook to `deliveries-webhook` (a Dashboard click-through) and setting the
  `FCM_PROJECT_ID`/`FCM_SERVICE_ACCOUNT_JSON` secrets (a Firebase-side credential, unavoidable
  regardless of where the code runs).
- ~~In-app admin screen~~ — **done.** `lib/screens/admin/admin_dashboard_screen.dart`
  (route `/admin`, reachable from the profile icon on the client dashboard and the app-bar icon
  on the rider dashboard). Lists + approves/rejects pending verifications, lists + creates
  companies. Gated by a `profiles.role` check in the screen itself (UI-only) and, for real,
  server-side inside the Edge Functions — nobody without `role = 'admin'` can act even if they
  reach the screen. **You still need to promote your own account to admin once** — no
  self-service path exists by design; run in the Supabase SQL editor:
  `update public.profiles set role = 'admin' where id = '<your auth uid>';`
- ~~"Rate your rider" flow~~ — **done.** `lib/screens/rate_rider_screen.dart` (route
  `/rate-rider`), reachable from a client's completed-delivery card once
  `CompletedDeliveriesScreen` was wired to real data (see below). Calls `submit-rating`.
- **Auth data migration** — no real Firebase users existed to migrate (confirmed pre-launch);
  nothing to import.
- **Firestore data backfill** — not applicable for the same reason.
- Old Firebase project (`dispatch-rider-2fb16-b28e7`) still holds Firebase Auth/Firestore/
  Storage config in the codebase's git history and `firebase.json`/`firestore.rules` — those
  are now unused by the Flutter app (Firebase is kept ONLY for `firebase_messaging`) and can be
  decommissioned once you're confident nothing else depends on them.
