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

Apply order matters — run them in numeric order against a fresh project.

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

- **Backend service** (Node/TypeScript, per decision) for: real push fan-out to riders who
  aren't the person who just created the delivery (today's `_notifyRidersOfNewDelivery` in
  `DeliveryService` is client-side/best-effort, same limitation as the old Firebase version —
  see the NOTE in `lib/services/delivery_service.dart`), rating recompute via
  `apply_rider_rating()` (service_role-only RPC, no caller yet), rider-verification review,
  company/invite provisioning.
- **In-app admin screen** — the RLS/DB side exists (0003), the Flutter UI does not.
- **Auth data migration** — no real Firebase users existed to migrate (confirmed pre-launch);
  nothing to import.
- **Firestore data backfill** — not applicable for the same reason.
- Old Firebase project (`dispatch-rider-2fb16-b28e7`) still holds Firebase Auth/Firestore/
  Storage config in the codebase's git history and `firebase.json`/`firestore.rules` — those
  are now unused by the Flutter app (Firebase is kept ONLY for `firebase_messaging`) and can be
  decommissioned once you're confident nothing else depends on them.
