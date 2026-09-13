# Migration — Phase 1 Design (Firebase → Supabase)

**Date:** 2026-09-06 · **Status:** design for review · **Nothing applied to any database.**
Companion to [FORENSIC_AUDIT.md](FORENSIC_AUDIT.md).

Artifacts produced in this phase:
- `supabase/migrations/0001_schema.sql` — tables, enums, indexes, triggers, functions, PostGIS
- `supabase/migrations/0002_policies.sql` — RLS policies + Storage policies
- `supabase/migrations/0003_transitions_and_admin.sql` — delivery state-machine trigger + in-app admin role
- this document — rationale, backend design, auth-migration method, open questions (§7 now resolved)

---

## 1. Phase 0 status

| Task | Owner | Status |
|---|---|---|
| `.gitignore` hardening (secrets, node_modules, `/android/build/`, ~37 agent dirs) | assistant | ✅ done — branch `chore/phase-0-cleanup`, commit `8cf0081` |
| `git rm --cached` secrets + vendored deps + agent tooling; one clean commit | assistant | ✅ done (same commit) |
| Delete admin-sdk key from disk | assistant | ✅ done |
| Merge `chore/phase-0-cleanup` → `main` | **you** | ⬜ review the commit, then `git checkout main && git merge chore/phase-0-cleanup` |
| Rotate Google Maps API key (`AIza…ClSjVI`) + restrict to Android app | **you** | ⬜ genuinely exposed (committed & pushed) |
| Rotate the admin-sdk key (`c1f777491e…`) — precaution | **you** | ⬜ was never pushed; low urgency |
| Make GitHub repo private | **you** | ⬜ |
| Snapshot **deployed** Firestore rules → overwrite `firestore.rules` | **you** | ⬜ `firebase firestore:rules get` or copy from console |
| Full backup: `gcloud firestore export gs://<bucket>/pre-migration` + Storage copy | **you** | ⬜ do before Phase 4; fine to do now |
| Record prod row counts (users, deliveries, companies, verifications) | **you** | ⬜ baseline for migration verification |

---

## 2. Locked decisions

| Topic | Decision | Consequence |
|---|---|---|
| Database | Firestore → Supabase Postgres | new schema (§3), RLS (§4), data backfill (§8) |
| Auth | Firebase Auth → Supabase Auth (GoTrue) | scrypt hash import, uid remap (§6) |
| Server logic | **External always-on backend service** (not Edge Functions) | new small repo, hosted on Render/Fly (§5) |
| Push | Keep **FCM**; backend does the sending | new FCM-only service account; Firebase project stays alive for Messaging (§5.3) |
| Web | Ship the Flutter web build to a static host | Cloudflare Pages / Netlify; likely an ops/admin surface |
| Tenancy | Finish `company_id` isolation during the port | baked into schema + RLS now |
| Realtime | Firestore `.snapshots()` → Supabase Realtime | 6 subscriptions remapped (§4.3) |
| Backend language | **Node / TypeScript** | §7 Q1 |
| Admin | **Real in-app admin role**, not backend-only | new RLS + trigger in `0003`; needs an admin UI in Phase 3 (§7 Q2) |
| Delivery lifecycle | rider can release; client can cancel with reason | enforced by DB trigger, `0003` (§7 Q3) |
| Rider phone | shown as-is to the client on a shared delivery | §7 Q4 |
| Spatial matching | **PostGIS enabled now** | generated `geography` columns, `0001` (§7 Q5) |
| Supabase region | **`eu-west-2` (London)** | matches existing projects + best real-world latency to Nigeria (§7 Q6) |
| Prod data volume | pre-launch / near-zero | simplifies Phase 4 — likely no maintenance window, likely skip hash import (§7 Q7) |

---

## 3. Schema rationale (`0001_schema.sql`)

**Collections → tables**

| Firestore | Postgres | Notable changes |
|---|---|---|
| `users/{uid}` | `profiles` (PK = `auth.users.id`) | email/phone-verified live in `auth.users`; `verification` map extracted to its own table; `companyCode` dropped (redundant with `company_id`); `latitude/longitude` → `last_lat/last_lng`; added `firebase_uid` bridge column (drop post-cutover) |
| `users.verification` (map) | `rider_verifications` | own table → clean RLS, admin review, `reviewed_by/at`, can't self-approve |
| `deliveries/{autoId}` | `deliveries` | `clientId`→`client_id`, `pickupLocation`→`pickup_address`, split coords into `*_lat/*_lng`, **`company_id` now NOT NULL** (fixes the "accepted param never written" bug), `payment_method` now persisted, `status` is an enum incl. `picked_up/in_transit/cancelled` (the UI already references these) |
| `deliveries/*/locationUpdates` | `delivery_locations` | flat table, FK + `on delete cascade`, `rider_id` denormalised for RLS |
| `companies/{autoId}` | `companies` | unchanged shape; `code` unique |

**Key functions/triggers**
- `handle_new_user()` — trigger on `auth.users` insert → creates the `profiles` row from sign-up
  metadata (`role`, `company_code`, `full_name`, `phone_number`, `firebase_uid`). The Flutter app
  passes these in `signUp(data: {...})`.
- `current_company_id()` / `current_role()` — `SECURITY DEFINER` helpers used by RLS to avoid
  recursive policy evaluation on `profiles`.
- `join_company(code)` — RPC so the invite-code lookup doesn't require opening `companies` to all
  users (fixes the audit R5 problem).
- `apply_rider_rating(rider, stars)` — server-side rating recompute (replaces the broken
  client-side `updateRiderRating`).

**Indexes** mirror the 3 real Firestore composite indexes plus tenant-scoped variants.

**PostGIS** — enabled (§7 Q5). `profiles.last_geog` / `deliveries.pickup_geog` are `geography`
columns **generated always as** from the plain `last_lat/last_lng` / `pickup_lat/pickup_lng`
columns, so the Flutter client keeps writing exactly what it writes today — no client change,
just better queries available to the backend service (`ST_DWithin`/`ST_Distance`, GIST-indexed).

---

## 4. Security model (`0002_policies.sql`)

This is the **corrected** version of `firestore.rules` (audit §4). Every table has RLS on.

### 4.1 What changed vs the Firebase rules

| Audit finding | Fix in RLS |
|---|---|
| R1 — any user reads every user's PII | `profiles` full-row select = self only; counterparties on a shared delivery see each other; admins see all. NIN/address/selfie moved to `rider_verifications` (self + admin only). |
| R2/R3 — `customerId` vs `clientId` field mismatch | consistent `client_id`; policies test real columns |
| R4 — `locationUpdates` had no rule | explicit insert (assigned rider, in-progress only) + select (participants) |
| R5 — `companies` had no rule; invite lookup blocked | `join_company()` RPC + `current_company_id()` helper; direct table select limited to own company |
| R6 — duplicate-email check ran unauthenticated | dropped entirely — GoTrue enforces email uniqueness natively |
| R7 — no tenant isolation | every `deliveries` policy is scoped by `company_id = current_company_id()` |

### 4.2 Delivery access matrix

| Actor | select | insert | update |
|---|---|---|---|
| Client | own orders | own, into own company, `pending` | own orders — cancel (`pending`/`accepted`, reason required) |
| Rider (same company) | own orders + `pending` pool | — | claim a `pending` job (→ `accepted`); progress own assigned job (`accepted→picked_up→in_transit→completed`); release `accepted→pending` |
| Rider (other company) | nothing | — | — |
| Admin | all | — | any row (force-cancel, reassign) |

The legal state machine — `pending → accepted → picked_up → in_transit → completed`, plus
`accepted → pending` (release) and `{pending, accepted} → cancelled` (reason required) — is
enforced by the `enforce_delivery_transition()` `BEFORE UPDATE` trigger in
`0003_transitions_and_admin.sql`, independent of RLS. Every other transition raises an error,
regardless of who/what issues the UPDATE (app, admin, or the backend service).

### 4.3 Realtime subscription mapping

| App location | Firestore | Supabase |
|---|---|---|
| `pending_deliveries_screen` | `deliveries where status==pending order createdAt` | `supabase.from('deliveries').stream(primaryKey:['id']).eq('status','pending')` — RLS restricts to same-company pool automatically |
| `active_deliveries_screen` | `where riderId==uid and status==accepted` | `.stream(...).eq('rider_id', uid).eq('status','accepted')` |
| client "my deliveries" | `where clientId==uid` | `.stream(...).eq('client_id', uid)` |
| completed (rider) | `where riderId==uid and status==completed` | `.stream(...)` + filter; also wire `CompletedDeliveriesScreen` (currently mock) |
| `confirm_delivery_screen` | single doc, wait for `status==accepted` | `.stream(...).eq('id', deliveryId)` |
| `track_order_screen` | `locationUpdates order timestamp desc limit 10` | `supabase.from('delivery_locations').stream(primaryKey:['id']).eq('delivery_id', id).order('recorded_at').limit(10)` |

Supabase `.stream()` needs the table in the `supabase_realtime` publication — done in `0001`.

---

## 5. Backend service design

New repo (suggested name `dispatch-rider-backend`). **Not** in this Flutter repo.

### 5.1 Responsibilities (moving OUT of the Flutter client)
1. **Push fan-out** — the piece that doesn't exist today. On new `pending` delivery: pick
   candidate riders, send FCM. On `accepted`: notify the client.
2. **Rider matching** — online + same company + within radius, ranked by rating/distance. The
   current client-side version (`DeliveryService._notifyRidersOfNewDelivery`) is broken (invalid
   multi-inequality query) and can't be trusted with tokens anyway.
3. **Verification review** — admin approve/reject → update `rider_verifications`, optionally gate
   the rider's ability to accept jobs.
4. **Rating recompute** — call `apply_rider_rating()` on completion.
5. **Company / invite-code provisioning** — admin-only.

### 5.2 Trigger mechanism
**Supabase Database Webhooks** (`pg_net`) → `POST https://<service>/hooks/deliveries` with a
shared-secret header, firing on `deliveries` INSERT/UPDATE. No polling, no persistent socket.
The service then queries Postgres (service_role) for candidate riders — using `ST_DWithin` if
PostGIS is enabled, else a bounding-box + Haversine query.

### 5.3 Auth & secrets
- Service → Supabase: **`service_role` key** (bypasses RLS), server-side only.
- Service → FCM: a **new dedicated service account** in the existing Firebase project with only
  *Firebase Cloud Messaging API* permission (FCM HTTP v1). **Not** the old admin-sdk key.
- Admin app → Service: verify the caller's Supabase JWT, check `role = 'admin'`.
- Webhook → Service: shared secret in a header.

### 5.4 Language & hosting
- **Language: Node + TypeScript** — best ecosystem fit for `@supabase/supabase-js` +
  `google-auth-library`/`firebase-admin` (FCM). (Dart `shelf` is viable and keeps one language;
  choose it only if the team strongly prefers Dart — the pricing/matching logic is ~50 lines to
  port either way.)
- **Hosting: Render Web Service** to start (GitHub auto-deploy, always-on, cheap, simple env-var
  secrets). Fly.io if you later need region control or scale-to-zero.
- Flutter **web** build → **Cloudflare Pages** (or Netlify) — static, separate from the service.

### 5.5 Endpoints (sketch)
```
POST /hooks/deliveries          ← Supabase webhook (shared secret)
POST /admin/verifications/:id   ← { action: approve|reject }  (admin JWT)
POST /admin/companies           ← create company + code       (admin JWT)
GET  /healthz
```

---

## 6. Auth migration method

**Chosen: transparent scrypt hash import** (no user disruption) — **but given §7 Q7 (pre-launch,
little/no real prod data), a full hash import is likely overkill.** Default to Phase 4 is:
**re-create the handful of test accounts directly in Supabase Auth** (fresh sign-ups) unless real
users have signed up by the time Phase 4 starts. Re-check data volume then; if it's grown, fall
back to the hash-import procedure below.

1. `firebase auth:export users.json --project dispatch-rider-2fb16-b28e7`
2. From Firebase console → Authentication → ⋮ → **Password hash parameters**, copy
   `hash_key (signer key)`, `salt_separator`, `rounds`, `mem_cost`.
3. Transform each user →
   - **new `id`**: generate a v4 uuid (Firebase uids are 28-char strings, not uuids). Keep a
     `firebase_uid → new_uuid` map (also stored on `profiles.firebase_uid`).
   - `encrypted_password`: Firebase-scrypt encoded string GoTrue understands
     (`$firebasescrypt$...` with the params above). Supabase documents this import path.
   - carry `email`, `email_confirmed_at`, `phone`, `created_at`.
4. Bulk insert into `auth.users` (service_role / SQL). The `handle_new_user` trigger fires →
   `profiles` rows created; then the data backfill (Phase 4) fills profile fields and rewires
   `deliveries.client_id/rider_id` via the uid map.
5. Users sign in with their **existing passwords**, unchanged.

**Fallback** (if hash params can't be retrieved): import users without passwords, force
"reset password" email on first login after cutover.

**Sign-up code change:** `AuthService` calls
`supabase.auth.signUp(email, password, data: { role, company_code, full_name, phone_number })`
so the trigger can populate the profile.

---

## 7. Open questions — RESOLVED (2026-09-13)

| # | Question | Decision |
|---|---|---|
| 1 | Backend language | **Node / TypeScript** |
| 2 | Admin surface | **Build a real in-app admin role now** — see `0003_transitions_and_admin.sql` (admin RLS write-policies + bootstrap note). Needs an admin screen/app surface in Phase 3. |
| 3 | Delivery state machine | **Rider can release** an `accepted` job back to `pending` (before pickup); **client can cancel with a required reason** while `pending` or `accepted`. Enforced by the `enforce_delivery_transition()` trigger in `0003_transitions_and_admin.sql` — illegal transitions raise an error no matter who/what writes. |
| 4 | Rider phone exposure | **Show the real phone number**, as today (counterparty policy already in `0002`). Revisit with a proxy/masking provider later if needed. |
| 5 | PostGIS | **Enabled now.** `0001_schema.sql` adds the extension + generated `geography` columns (`profiles.last_geog`, `deliveries.pickup_geog`) kept in sync from plain lat/lng — the Flutter client is unchanged. The backend uses `ST_DWithin`/`ST_Distance` for matching (query sketch included in the file). |
| 6 | Region | **`eu-west-2` (London)** — matches your other two projects, and in practice out-performs Frankfurt for Nigerian traffic since most West African subsea cables (MainOne, WACS, ACE) land/peer through the UK. |
| 7 | Data volume | **Pre-launch / testing — little to no real production data.** This removes the hardest part of Phase 4: no maintenance window is needed, and since there are effectively no real users yet, **the Auth "hash import" in §6 can likely be skipped in favor of fresh Supabase sign-ups** (re-register the handful of test accounts) unless you want to keep specific test logins. Re-confirm at Phase 4 kickoff in case real users signed up in the meantime. |

All 7 are now closed. Nothing left blocking Phase 2.

---

## 8. Preview of Phase 4 (data backfill) — not now, for context

```
firestore export ──▶ transform script ──▶ Supabase
  users.json          - gen uuid per firebase_uid, build map
  firestore/*         - users     → auth.users (+ scrypt pw) → profiles (trigger) → UPDATE profile fields
                       - companies → companies (keep codes)
                       - deliveries→ deliveries (remap client_id/rider_id via uid map; company_id from client)
                       - locationUpdates → delivery_locations
                       - verification map → rider_verifications
  storage             - gsutil cp rider_verification/** → supabase storage 'rider-verification/{new_uuid}/...'
verify: row counts match recorded baseline; spot-check 10 deliveries end to end
```

---

## 9. What to do next

1. Review & merge `chore/phase-0-cleanup` (now also carries Phase 2 + 3 work — see below).
2. Do the human Phase 0 items in §1 (key rotation, repo private, rules snapshot, backup) —
   **still outstanding**, independent of the Supabase work.
3. ~~Answer §7~~ — done (2026-09-13).
4. ~~Phase 2~~ — **done (2026-09-13).** Supabase project `dispatch-rider`
   (`bvztrnekmjaulwsjymcc`, eu-west-2) created; migrations `0001`–`0007` applied (schema, RLS,
   state machine + admin, security hardening, default company, rider_verifications reshaped to
   match the actual UI, direct accepted→completed allowed). Full detail in `supabase/README.md`.
5. ~~Phase 3 (app port)~~ — **done (2026-09-13)**, ahead of schedule (the Node/TS backend
   scaffold and in-app admin screen were deferred — see below). `pubspec.yaml` now depends on
   `supabase_flutter`; `firebase_core`/`firebase_messaging` are the only Firebase packages left
   (push only). `AuthService`, `DeliveryService`, `LocationTrackingService`, `CompaniesService`,
   `TenantService`, and every screen that touched Firestore/Firebase Auth directly are ported.
   `flutter analyze` is clean (0 errors); `flutter test` is 4/5 (1 pre-existing, unrelated flake).
6. **Still open / Phase 4 candidates:**
   - Backend service (Node/TS) for real push fan-out, `apply_rider_rating()` caller, verification
     review, company provisioning — the client-side notification path is still best-effort/local,
     same limitation the Firebase version had.
   - In-app admin screen (RLS already supports it, §7 Q2).
   - Data backfill — **not needed**: confirmed pre-launch, zero real Firebase users/deliveries.
   - Decommission the old Firebase project once nothing else depends on it (Messaging is the
     only remaining consumer).
