# Dispatch Rider — backend service

Node/TypeScript service filling the gaps Supabase itself doesn't cover:
**real push fan-out**, **rider matching**, **rating submission**, **verification review**,
**company provisioning**. Talks to Supabase with the `service_role` key (bypasses RLS) and to
FCM via HTTP v1. See [`../MIGRATION_PHASE1_DESIGN.md`](../MIGRATION_PHASE1_DESIGN.md) §5 for the
design rationale and [`../supabase/README.md`](../supabase/README.md) for the DB side.

## Endpoints

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/healthz` | none | liveness check |
| POST | `/hooks/deliveries` | `x-webhook-secret` header | Supabase Database Webhook target — fans out push on new `pending` deliveries, notifies the client when accepted |
| POST | `/deliveries/:id/rating` | Supabase user JWT | client rates the rider of their own completed delivery (calls `apply_rider_rating` RPC) |
| GET / POST | `/admin/verifications[/:id]` | Supabase user JWT, `role = admin` | list pending rider verifications / approve or reject one |
| GET / POST | `/admin/companies` | Supabase user JWT, `role = admin` | list companies / create one + invite code |

Auth model: the Flutter app's Supabase session access token is sent as `Authorization: Bearer
<token>`; the service calls `supabase.auth.getUser(token)` to verify it (no need to manage the
project's JWT signing secret separately), then reads the caller's `profiles.role` for the
`/admin/*` routes.

## Local development

```bash
cd backend
npm install
cp .env.example .env   # fill in the real values, see below
npm run dev
```

## Environment variables

See `.env.example`. You need:

1. **`SUPABASE_SERVICE_ROLE_KEY`** — Supabase Dashboard → this project → Project Settings → API
   → `service_role` **secret** key. Treat like a root password; never put it in the Flutter app
   or commit it.
2. **`WEBHOOK_SHARED_SECRET`** — any long random string you generate (e.g. `openssl rand -hex 32`).
3. **`FCM_PROJECT_ID`** / **`FCM_SERVICE_ACCOUNT_JSON`** — a **new, dedicated** service account in
   the existing Firebase project (`dispatch-rider-2fb16-b28e7`), scoped to Firebase Cloud
   Messaging only:
   - Firebase Console → Project Settings → Service Accounts → "Generate new private key", OR
     Google Cloud Console → IAM → Service Accounts → Create → grant only the
     **Firebase Cloud Messaging API Admin** role.
   - **Do not reuse** the old Firestore admin-sdk key (the one flagged in `FORENSIC_AUDIT.md` —
     it should already be rotated/deleted per that report).
   - Paste the downloaded JSON file's contents as a single-line string into
     `FCM_SERVICE_ACCOUNT_JSON` (env vars can't hold literal newlines; the JSON's own
     `\n`-escaped `private_key` field is fine as-is).

## Deploying to Render

1. Push this repo (or just the `backend/` folder, if you split it out) to GitHub.
2. Render Dashboard → New → Blueprint → point at the repo → it reads `render.yaml`.
   (Or: New → Web Service → root directory `backend`, build command
   `npm install && npm run build`, start command `npm start`.)
3. Fill in the 5 environment variables in the Render dashboard (marked `sync: false` in
   `render.yaml` so Render prompts for them rather than expecting them in git).
4. Deploy. Note the resulting URL, e.g. `https://dispatch-rider-backend.onrender.com`.

## Wiring the Supabase Database Webhook

Once deployed, in the Supabase Dashboard → Database → Webhooks → Create a new hook:

- **Table:** `deliveries`
- **Events:** Insert, Update
- **Type:** HTTP Request
- **URL:** `https://<your-render-url>/hooks/deliveries`
- **HTTP Headers:** `x-webhook-secret: <the same WEBHOOK_SHARED_SECRET>`

(Equivalently, this can be created via SQL using `pg_net` + a trigger — the Dashboard UI does
exactly that under the hood and is simpler to get right the first time.)

## What this does NOT do (yet)

- No retry/queue for failed pushes — a dropped webhook call means that delivery doesn't get a
  push; the app's realtime `deliveries` subscription is still the source of truth for state,
  push is purely a notification convenience, matching how the original Firebase version treated
  it (see `FORENSIC_AUDIT.md` §5).
- No rate limiting / abuse protection on the `/admin/*` or `/deliveries/:id/rating` routes —
  fine at pre-launch scale, revisit before real traffic.
- The in-app admin UI (Flutter) that would call `/admin/*` doesn't exist yet — these are ready
  to be called (e.g. from `curl`/Postman) but nothing in the app does so yet.
