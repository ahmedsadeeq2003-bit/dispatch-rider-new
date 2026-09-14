# Dispatch Rider — Forensic Audit & Migration Readiness Report

**Date:** 2026-09-06
**Repo:** `dispatch_rider_new` (branch `main`, single commit `de6d2be`)
**Remote:** `github.com/ahmedsadeeq2003-bit/dispatch-rider-new`
**Goal:** Move the database off Firebase (→ Supabase) and change application hosting.
**Scope of this document:** audit only. **No migration performed.**

---

## 0. TL;DR

The app is a **Flutter mobile app** (Android + iOS + stub web/desktop) for connecting dispatch
riders with clients. It uses Firebase for **Auth, Cloud Firestore, Storage, and Cloud Messaging**.
There is **no backend/server code and no Firebase Hosting or Cloud Functions** — all logic runs
client-side.

Before any migration work, fix these (see §1):

1. A **Firebase Admin service-account private key** sits in the working tree at
   `seed-script/dispatch-rider-2fb16-b28e7-firebase-adminsdk-fbsvc-c1f777491e.json`. **Verified:
   it was staged in the local git index but never committed and never pushed** — `origin/main` is
   the single commit `de6d2be` (164 files) and does not contain it. So this is a *near miss*, not
   a public leak. Still: delete the file from disk, keep it untracked (done), and rotating the key
   is a cheap precaution.
2. A **Google Maps API key IS committed and pushed** (`AndroidManifest.xml`, in `de6d2be`) and
   appears unrestricted. Rotate + restrict — this one is genuinely exposed.
3. `android/app/google-services.json` **is committed and pushed** — client Firebase identifiers,
   low severity, but lock down API keys + App Check while still on Firebase.
4. The **Firestore security rules are broken and/or bypassed** (field-name mismatches, missing
   rules for whole collections). Whatever is actually protecting production data today is unknown
   from the repo — likely a permissive console rule.

**Also note:** the local git index has ~3,377 files staged on top of the 164-file `de6d2be`
commit (the entire `.adal/`, `ios/`, `.dart_tool` outputs, etc.). The working state is messy;
recommend a clean re-commit with a proper `.gitignore` before migration branches start.

The migration itself is **medium-sized but not huge**: ~6,000 lines of Dart, 4 Firestore
collections, ~6 realtime streams, 1 Storage bucket path, and a **non-functional** push layer that
will have to be rebuilt regardless.

---

## 1. CRITICAL SECURITY FINDINGS (fix before migration)

### 1.1 Firebase Admin SDK private key in working tree — SEV-3 (near miss, not exposed)
- **File:** `seed-script/dispatch-rider-2fb16-b28e7-firebase-adminsdk-fbsvc-c1f777491e.json`
- Contains `"type": "service_account"` + `"private_key"` for
  `firebase-adminsdk-fbsvc@dispatch-rider-2fb16-b28e7.iam.gserviceaccount.com`
  (key id `c1f777491e880d4584da6b7a3f870a4dcb74035f`). This key bypasses all security rules.
- **Verified NOT exposed:** `origin/main` == `de6d2be` (164 files) and does not contain it.
  The file was `git add`-ed into the local index but never committed/pushed. `git rm --cached`
  applied (this session) — it is no longer staged and `.gitignore` now excludes it.
- **Action:**
  1. `rm seed-script/dispatch-rider-2fb16-b28e7-firebase-adminsdk-fbsvc-c1f777491e.json` from disk.
  2. Precautionary: Google Cloud Console → IAM & Admin → Service Accounts → this account → Keys →
     delete key `c1f777491e880d4584da6b7a3f870a4dcb74035f`.
  3. The `seed-script/` will be replaced by a SQL seed during migration anyway.

### 1.2 Google Maps API key committed — SEV-2
- `android/app/src/main/AndroidManifest.xml`: `com.google.android.geo.API_KEY` =
  `AIzaSyA3w4Xuvt72tSTdurpx_4T3AVcEQClSjVI`.
- **Action:** rotate the key; restrict by Android app (package + SHA-1) and by API (Maps SDK
  only). Move to a build-time secret / `local.properties` injection, not source.

### 1.3 Firebase client config committed
- `lib/firebase_options.dart` and `android/app/google-services.json` contain the web/android/iOS
  API keys. These are *identifiers*, not secrets, but with weak Firestore rules they are the only
  thing standing between the internet and the data.
- **Action (while still on Firebase):** add API key restrictions + enable **App Check**. Not
  needed post-Supabase.

### 1.4 `seed-script/node_modules/` committed
- 5,579 vendored files in git. Bloat + supply-chain surface. Add to `.gitignore`, `git rm -r --cached`.

### 1.5 Minor
- Stray empty tracked file: `c` (repo root).
- `print()` debug statements leak user coordinates and pricing to device logs
  (`pricing_utils.dart`, `dispatch_order_screen.dart`).

---

## 2. CURRENT ARCHITECTURE

```
Flutter app (lib/, ~6,005 LOC Dart, 31 files)
├── firebase_core / firebase_options.dart      → Firebase project dispatch-rider-2fb16-b28e7
├── firebase_auth (email+password)             → login/register for client & rider
├── cloud_firestore                            → all app data + realtime
├── firebase_storage                           → rider verification images
├── firebase_messaging + flutter_local_notifications → push (SEE §5 — not functional)
├── flutter_map + OpenStreetMap/Nominatim      → maps, geocoding, autocomplete (NOT Google)
└── geolocator / location                      → device GPS

Backend: NONE. No Cloud Functions, no server, no Firebase Hosting.
firebase.json configures only Firestore rules + indexes.
```

**Platforms:** Android (primary), iOS (partly configured — no `GoogleService-Info.plist`),
web + windows + linux + macos targets exist but are stock template / not wired for Firebase web.

**Third-party services already in use (not Firebase, unaffected by migration):**
- OpenStreetMap tiles, Nominatim search API (Adamawa/Abuja/Kaduna, Nigeria).
- Google Maps API key present in manifest but code uses `flutter_map` — key may be unused/legacy.

---

## 3. DATA MODEL (Firestore → must become Postgres schema)

### `users/{uid}`  (uid == Firebase Auth UID)
| field | type | notes |
|---|---|---|
| name | string | |
| email | string | duplicated from Auth |
| phoneNumber | string | riders only |
| role | string | `client` \| `rider` |
| companyCode / companyId | string | multi-tenant, **partially implemented** |
| latitude / longitude | double | rider live position (denormalised onto user) |
| lastLocationUpdate | timestamp | |
| isOnline | bool | rider availability |
| rating | double | default 5.0 |
| totalDeliveries / totalRatings | number | running totals; average computed client-side |
| fcmToken | string | device push token |
| lastUpdated / createdAt | timestamp | |
| verification | map | `{ nin, address, proofUrl, selfieUrl, fullName, status: pending, submittedAt }` — PII, incl. National ID |

### `deliveries/{autoId}`
| field | type | notes |
|---|---|---|
| clientId | string | Auth UID of client |
| riderId | string \| null | Auth UID of rider once accepted |
| pickupLocation / destination | string | free text |
| pickupLat/pickupLon/destLat/destLon | double? | nullable |
| weight | double | |
| packageType | string | `Small Package` \| `Large Package` |
| price | double | Naira, computed client-side (`PricingUtils`) |
| status | string | `pending` \| `accepted` \| `completed` |
| createdAt / acceptedAt / completedAt | timestamp | |
| ~~companyId~~ | — | **param accepted but never written** (bug, §6) |
| ~~paymentMethod~~ | — | **param accepted but never written** (bug, §6) |

### `deliveries/{id}/locationUpdates/{autoId}`  (subcollection — rider breadcrumb trail)
`latitude, longitude, timestamp, speed, accuracy`

### `companies/{autoId}`
`code (e.g. "DEFAULT"), name, plan, status, createdAt` — created only by `seed-script/seed.js`.

### Realtime listeners (`.snapshots()`) — must map to Supabase Realtime / `.stream()`
| location | query |
|---|---|
| `DeliveryService.getPendingDeliveries` | `deliveries where status==pending order by createdAt desc` |
| `DeliveryService.getActiveDeliveries(uid)` | `deliveries where riderId==uid and status==accepted order by acceptedAt desc` |
| `DeliveryService.getClientDeliveries(id)` | `deliveries where clientId==id order by createdAt desc` |
| `DeliveryService.getCompletedDeliveries(id)` | `deliveries where riderId==id and status==completed` |
| `confirm_delivery_screen` | single `deliveries/{id}` doc — waits for `status==accepted` |
| `LocationTrackingService.getLocationUpdates` | `locationUpdates order by timestamp desc limit 10` |

### Storage
- Bucket `dispatch-rider-2fb16-b28e7.firebasestorage.app`
- Paths: `rider_verification/proof_{uid}/{ts}.jpg`, `rider_verification/selfie_{uid}/{ts}.jpg`
- **No Storage security rules in repo** (`firebase.json` has no `storage` block).

### Composite indexes (`firestore.indexes.json`)
- Contains garbage collection-group names (`active%20deliveries`, `completed%20deliveries` — URL
  encoded, don't exist in code). Only `deliveries` composite indexes on
  `(riderId,status,acceptedAt)`, `(riderId,status,completedAt)`, `(status,createdAt)` are real.

---

## 4. FIRESTORE SECURITY RULES — BROKEN / BYPASSED

`firestore.rules` (deployed state unknown) has serious problems. These matter because **the rules
are the spec for Supabase Row-Level Security** — you'll re-implement them, so fix the intent now.

| # | Problem | Effect |
|---|---|---|
| R1 | `users` read = `if request.auth != null` | **Any logged-in user can read every user's** email, phone, GPS, NIN, home address, selfie URL. |
| R2 | `deliveries` create checks `request.resource.data.customerId == uid`, but the app writes **`clientId`** | Field-name mismatch — rule guards a field that doesn't exist. Either creates fail, or console rules are permissive. |
| R3 | `deliveries` read/update reference `resource.data.customerId` — same mismatch | Customers can't read their own orders under these rules. |
| R4 | `locationUpdates` subcollection — **no rule** | Denied by default → live location writes fail unless a broad console rule exists. |
| R5 | `companies` — **no rule** | Denied by default → registration's `companies where code==…` lookup fails unless overridden. |
| R6 | Registration queries `users where email==…` **before** `createUserWithEmailAndPassword` (unauthenticated) | Blocked by R1's `auth != null` → duplicate-email check is dead code unless console rules allow anon read. |
| R7 | No `companyId` tenant isolation anywhere | Any rider can see any company's pending jobs. Multi-tenant is a stated goal (4 TODO files) but unbuilt. |

**Conclusion:** production is almost certainly running with a permissive catch-all rule
(`allow read, write: if request.auth != null;` — the "quick fix" from `FIREBASE_SETUP.md`).
Treat all current data as effectively readable by any authenticated account.

---

## 5. PUSH NOTIFICATIONS — CURRENTLY NON-FUNCTIONAL

- `NotificationService` gets an FCM token and wires foreground/opened handlers.
- **Background handler is a `static` class method** passed to `onBackgroundMessage`. Firebase
  requires a **top-level function annotated `@pragma('vm:entry-point')`** — current code will not
  work for background messages on Android.
- **There is no server that sends FCM messages.** `DeliveryService._sendNotificationToRiders` and
  `_sendNotificationToClient` only `print()` and raise a **local** notification on the *sender's*
  device. Riders never receive a remote "new job" push. The whole rider-matching notification
  flow is a simulation.
- iOS: no `GoogleService-Info.plist`, no APNs key configured → FCM on iOS not set up.

**Implication for migration:** Supabase has **no push service**. You will need FCM (kept) or a
third party (OneSignal / Expo push), driven from a **Supabase Edge Function** or other backend.
This work is required no matter what, since it doesn't exist today.

---

## 6. FUNCTIONAL BUGS & DEAD CODE (relevant to a rebuild)

| Area | Issue |
|---|---|
| `DeliveryService.createDeliveryRequest` | accepts `companyId` + `paymentMethod` but **never writes them** to the doc. |
| `TenantService.requireCurrentCompanyId()` | throws `StateError` if user doc lacks `companyId`; client registration allows empty code, legacy users have none → **"Confirm & Search for Rider" will crash** for most users. |
| `_notifyRidersOfNewDelivery` | Firestore query chains `where(isOnline)` + `where(latitude != null)` + `where(longitude != null)` — invalid multi-inequality / needs indexes; almost always falls to the `catch` → notify-all path. |
| `CompletedDeliveriesScreen` | 100% hardcoded mock data; never queried Firestore despite `TODO_FIRESTORE.md` claiming "fully real & working". |
| `RiderAuthScreen` | "Rider Login" button navigates straight to `/rider-dashboard` — **no authentication**. |
| `auth_service.loginUser` | routes by `users/{uid}.role`; a rider using the client login screen still lands on client dashboard. |
| `TrackOrderScreen` | rider name/phone/vehicle/rating all mock; timeline steps never advance; `_interpolateRoute` unused. |
| `firebase_options.dart` | web + windows `authDomain` = `dispatch-rider-2fb16-b28-59517.firebaseapp.com` — **does not match** project `dispatch-rider-2fb16-b28e7`. Web/Windows Auth likely broken. |
| `google-services.json` vs `firebase.json` | two different Android `appId`s registered (`…1c8c406…` and `…da36762…`). |
| Duplicate imports | `rider_dashboard_screen.dart`, `location_tracking_service.dart`. |
| Release signing | Android release build signed with **debug keys** (`build.gradle.kts` TODO). |
| `applicationId` | still `com.example.dispatch_rider_new` (default). |
| Branding | inconsistent: "Senditt" (tests/UI), "Dispatch Rider", "Dispatch Rider New"; `support@senditt.com` vs `support@dispatchrider.com`. |
| Tests | 5 widget tests on `WelcomeScreen` only; none for services, auth, delivery flow. |
| `async`/`context` | `BuildContext` used across `await` gaps throughout without `mounted` guards. |

---

## 7. WHAT "CHANGE HOSTING" ACTUALLY MEANS HERE

There is **no Firebase Hosting deployment** to move. `firebase.json` only ships Firestore
rules/indexes. Practical hosting needs created by (or exposed by) this migration:

1. **Server-side compute** (new requirement): push fan-out, rider-matching, verification
   approval, rating recomputation, tenant provisioning. **Chosen: an external always-on backend
   service** (Node or Dart) on Fly.io / Render / Cloud Run — talks to Supabase with the
   service-role key and to FCM HTTP v1.
2. **Flutter web build hosting**: **in scope** — static host (Cloudflare Pages / Netlify).
   Likely an ops/admin surface rather than the customer app. Supabase does not host SPAs.
3. **Mobile distribution** (unchanged by DB choice): Play Store / App Store / Firebase App
   Distribution or TestFlight.

---

## 8. MIGRATION SURFACE — EFFORT ESTIMATE

| Component | Firebase | Supabase target | Effort |
|---|---|---|---|
| Auth (email/password) | `firebase_auth` | `supabase_flutter` GoTrue | S–M (routing/role logic is tangled in `AuthService`) |
| User profiles | `users` collection | `profiles` table, FK to `auth.users` | S |
| Deliveries | `deliveries` collection | `deliveries` table + enum status | M |
| Location trail | `locationUpdates` subcollection | `delivery_locations` table (or PostGIS) | S–M |
| Companies / tenancy | `companies` collection | `companies` table + `company_id` FKs + RLS | M (also finishes unbuilt feature) |
| Realtime (6 streams) | `.snapshots()` | Supabase Realtime `.stream()` / Postgres CDC | M |
| Security rules | `firestore.rules` | RLS policies (rewrite §4 intent correctly) | M |
| Indexes | `firestore.indexes.json` | `CREATE INDEX` | S |
| Storage (verification imgs) | Firebase Storage | Supabase Storage bucket + policies | S |
| Push | FCM (broken) | Edge Function + FCM/OneSignal | M–L (net-new) |
| Server logic | none | Edge Functions | M |
| Data backfill | — | export Firestore → transform → `COPY`/insert | S–M (depends on prod data volume) |
| Config/CI/hosting | `firebase.json` | Supabase project + web host + secrets mgmt | S–M |

Rough order-of-magnitude: **2–4 focused weeks** for a clean cutover including finishing tenancy
and building a real push path, less if web/push are deferred.

---

## 9. NEXT STEPS (no DB move yet)

### Decisions locked in (2026-09-06)
| Question | Decision |
|---|---|
| Secret containment | User rotates key + makes repo private; assistant handles `.gitignore` + `git rm --cached` + history guidance. **`git rm --cached` done this session** (key was never pushed — §1.1). |
| Server-side logic host | **External backend service** (Node or Dart) on Fly.io / Render / Cloud Run — *not* Supabase Edge Functions. |
| Flutter web | Mobile-first, but **also host the web build** (Cloudflare Pages / Netlify) — likely for an ops/admin view. |
| Auth | **Migrate to Supabase Auth** (GoTrue). Existing Firebase users → import scrypt hashes or force one-time reset. |
| Push | **Keep FCM**, build the missing server side (backend service calls FCM HTTP v1 on new deliveries). Firebase project stays alive for Messaging only. |
| Multi-tenant | Recommend finishing `companyId` isolation during the port (RLS makes it cheap). Confirm at Phase 2. |

### Phase 0 — Contain & clean (this week, before Supabase)
- [x] `.gitignore` hardened; `git rm --cached` for `seed-script/node_modules`, admin-sdk json,
      `google-services.json`, stray `c`, `android/build/`. **Commit this.**
- [ ] `rm` the admin-sdk json from disk. Rotate the key + the Maps API key (§1.1, §1.2); restrict
      the Maps key to the Android app.
- [ ] Make the GitHub repo private.
- [ ] Clean re-commit: the index has ~3,377 staged files on top of `de6d2be`. Decide what belongs
      in the repo (`.adal/` skills? build outputs? — probably not) and make one tidy commit so
      migration branches start from a known state.
- [ ] Snapshot the **actual deployed** Firestore rules from the console into `firestore.rules`.
- [ ] `gcloud firestore export` full backup + `gsutil` Storage backup. Record prod row counts.

### Phase 1 — Design (no code)
- [ ] Draft the Postgres schema + enums + indexes (from §3) and RLS policy set (corrected §4
      intent). Review together before applying.
- [ ] Decide the backend service shape: language (Dart `shelf` keeps one language; Node has more
      Supabase/FCM examples), hosting (Render is simplest for a always-on small service), and its
      responsibilities: push fan-out, rider matching, verification approval, rating recompute,
      tenant/invite provisioning.
- [ ] Decide the Auth user-migration method (hash import vs reset).

### Phase 2 — Stand up Supabase in parallel (still no cutover)
- [ ] Create a Supabase project in org `ciqhryhdhpldojfgaacm` (region `eu-west-2` to match the
      existing projects; **no dispatch-rider project exists yet**).
- [ ] Apply schema as versioned SQL migrations. Apply RLS. Create Storage bucket
      `rider-verification` with owner-scoped policies.
- [ ] Scaffold the backend service repo; wire it to Supabase (service-role key) + FCM HTTP v1.
- [ ] In the Flutter app, introduce a `DataService` / repository seam so screens stop calling
      `FirebaseFirestore.instance` directly. Ship this refactor first, still on Firebase — it's
      the switch that makes the cutover flippable and is safe to do now.

### Phase 3 — Port the app behind a flag
- [ ] Add `supabase_flutter`; implement `DataService` + Auth + Storage against Supabase.
- [ ] Replace the 6 realtime streams (§3) with Supabase Realtime.
- [ ] Point push at the new backend; implement the FCM send path; fix the background-handler bug.
- [ ] Fix §6 bugs while porting (companyId + paymentMethod writes, tenant guard, matching query,
      rider-login-with-no-auth, authDomain).
- [ ] Wire `CompletedDeliveriesScreen` to real data. Add service-level tests.

### Phase 4 — Migrate data & cut over
- [ ] Build the Firestore-export → Postgres transform script. Dry-run into the Supabase project;
      verify counts + spot checks.
- [ ] Migrate Auth users.
- [ ] Maintenance window: freeze writes, final export + load, flip the flag, submit app updates.
- [ ] Deploy the web build to the chosen static host.
- [ ] Keep Firebase (Firestore read-only) for a rollback window; then decommission all but
      Messaging.

---

## 10. APPENDIX — File inventory

**Firebase-touching Dart files (must change):**
`lib/main.dart`, `lib/firebase_options.dart`, `lib/services/auth_service.dart`,
`lib/services/delivery_service.dart`, `lib/services/location_tracking_service.dart`,
`lib/services/notification_service.dart`, `lib/services/companies_service.dart`,
`lib/services/tenant_service.dart`, `lib/screens/confirm_delivery_screen.dart`,
`lib/screens/track_order_screen.dart`, `lib/screens/pending_deliveries_screen.dart`,
`lib/screens/active_deliveries_screen.dart`, `lib/screens/profile_screen.dart`,
`lib/screens/rider_dashboard_screen.dart`, `lib/screens/rider_verification_screen.dart`,
`lib/screens/completed_deliveries_screen.dart` (currently mock).

**Config to replace:** `firebase.json`, `.firebaserc`, `firestore.rules`,
`firestore.indexes.json`, `android/app/google-services.json`, `android/app/build.gradle.kts`
(google-services plugin), `lib/firebase_options.dart`.

**Delete / rework:** `seed-script/` (→ SQL seed), `FIREBASE_SETUP.md`, `TODO_FIRESTORE.md`.

**pubspec — remove:** `firebase_core`, `firebase_auth`, `firebase_messaging`, `cloud_firestore`,
`firebase_storage`. **add:** `supabase_flutter` (+ push SDK).
