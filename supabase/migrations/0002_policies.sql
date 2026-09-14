-- ============================================================================
-- Dispatch Rider — RLS policies + Storage (Phase 1 DESIGN — not yet applied)
-- Implements the CORRECTED intent of firestore.rules (see FORENSIC_AUDIT.md §4).
-- Principle: least privilege, tenant isolation by company_id, no cross-user PII.
-- ============================================================================

alter table public.companies            enable row level security;
alter table public.profiles             enable row level security;
alter table public.rider_verifications  enable row level security;
alter table public.deliveries           enable row level security;
alter table public.delivery_locations   enable row level security;

-- ---------------------------------------------------------------------------
-- companies : no direct table access for users. Reads/joins go through
--             public.join_company() and public.current_company_id() (SECURITY
--             DEFINER). Backend uses service_role (bypasses RLS).
-- ---------------------------------------------------------------------------
create policy companies_read_own on public.companies
  for select to authenticated
  using (id = public.current_company_id());

-- ---------------------------------------------------------------------------
-- profiles
--   * full row visible only to yourself
--   * counterparties on a shared delivery can see each other (name/phone/rating)
--   * admins see all
--   * you may update only your own row; role/company_id changes blocked here
--     (company_id is set via join_company(); role changes are admin/service only)
-- ---------------------------------------------------------------------------
create policy profiles_select_self on public.profiles
  for select to authenticated
  using (id = auth.uid());

create policy profiles_select_delivery_counterparty on public.profiles
  for select to authenticated
  using (exists (
    select 1 from public.deliveries d
    where (d.client_id = auth.uid() and d.rider_id = profiles.id)
       or (d.rider_id  = auth.uid() and d.client_id = profiles.id)
  ));

create policy profiles_select_admin on public.profiles
  for select to authenticated
  using (public.current_role() = 'admin');

create policy profiles_update_self on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (
    id = auth.uid()
    and role = (select role from public.profiles where id = auth.uid())
    and company_id is not distinct from (select company_id from public.profiles where id = auth.uid())
  );
-- NOTE: INSERT is done by the on_auth_user_created trigger (SECURITY DEFINER),
-- so no INSERT policy is granted to users.

-- ---------------------------------------------------------------------------
-- rider_verifications
--   * a rider sees & submits/edits only their own, only while 'pending'
--   * a rider can never set status to approved/rejected (admin/service only)
--   * admins see & review all
-- ---------------------------------------------------------------------------
create policy rv_select_own on public.rider_verifications
  for select to authenticated
  using (rider_id = auth.uid() or public.current_role() = 'admin');

create policy rv_insert_own on public.rider_verifications
  for insert to authenticated
  with check (rider_id = auth.uid() and status = 'pending');

create policy rv_update_own_pending on public.rider_verifications
  for update to authenticated
  using (rider_id = auth.uid() and status = 'pending')
  with check (rider_id = auth.uid() and status = 'pending');

create policy rv_admin_all on public.rider_verifications
  for all to authenticated
  using (public.current_role() = 'admin')
  with check (public.current_role() = 'admin');

-- ---------------------------------------------------------------------------
-- deliveries
--   SELECT : my orders (as client or rider), OR pending jobs in MY company if I'm a rider
--   INSERT : only as the client, into my own company, status must start 'pending'
--   UPDATE : client on own order | rider claiming a pending same-company job
--            | assigned rider progressing status
--   DELETE : never
--   (Fine-grained state-machine checks — e.g. which transitions are legal —
--    are enforced by a BEFORE UPDATE trigger, see 0003_transitions.sql TODO.)
-- ---------------------------------------------------------------------------
create policy deliveries_select_mine on public.deliveries
  for select to authenticated
  using (client_id = auth.uid() or rider_id = auth.uid());

create policy deliveries_select_pending_pool on public.deliveries
  for select to authenticated
  using (
    status = 'pending'
    and company_id = public.current_company_id()
    and public.current_role() = 'rider'
  );

create policy deliveries_select_admin on public.deliveries
  for select to authenticated
  using (public.current_role() = 'admin');

create policy deliveries_insert_client on public.deliveries
  for insert to authenticated
  with check (
    client_id = auth.uid()
    and company_id = public.current_company_id()
    and status = 'pending'
    and rider_id is null
  );

create policy deliveries_update_client_own on public.deliveries
  for update to authenticated
  using (client_id = auth.uid())
  with check (client_id = auth.uid());

create policy deliveries_update_rider_claim on public.deliveries
  for update to authenticated
  using (
    status = 'pending'
    and company_id = public.current_company_id()
    and public.current_role() = 'rider'
  )
  with check (rider_id = auth.uid() and status = 'accepted');

create policy deliveries_update_rider_assigned on public.deliveries
  for update to authenticated
  using (rider_id = auth.uid())
  with check (rider_id = auth.uid());

-- ---------------------------------------------------------------------------
-- delivery_locations
--   INSERT : only the assigned rider, only while the delivery is in progress
--   SELECT : the delivery's client or rider (admins via delivery policy)
-- ---------------------------------------------------------------------------
create policy dloc_insert_assigned_rider on public.delivery_locations
  for insert to authenticated
  with check (
    rider_id = auth.uid()
    and exists (
      select 1 from public.deliveries d
      where d.id = delivery_id
        and d.rider_id = auth.uid()
        and d.status in ('accepted', 'picked_up', 'in_transit')
    )
  );

create policy dloc_select_participants on public.delivery_locations
  for select to authenticated
  using (exists (
    select 1 from public.deliveries d
    where d.id = delivery_id
      and (d.client_id = auth.uid() or d.rider_id = auth.uid())
  ));

-- ============================================================================
-- STORAGE : bucket 'rider-verification' (PRIVATE)
-- Path convention: rider-verification/{auth.uid}/proof-{ts}.jpg
--                  rider-verification/{auth.uid}/selfie-{ts}.jpg
-- Create the bucket in Phase 2 (dashboard or `supabase storage`), then:
-- ============================================================================
-- insert into storage.buckets (id, name, public) values ('rider-verification','rider-verification', false);

create policy "rv objects: owner rw" on storage.objects
  for all to authenticated
  using (
    bucket_id = 'rider-verification'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'rider-verification'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "rv objects: admin read" on storage.objects
  for select to authenticated
  using (bucket_id = 'rider-verification' and public.current_role() = 'admin');

-- ============================================================================
-- OPEN QUESTIONS for review (see MIGRATION_PHASE1_DESIGN.md §7):
--  1. Should clients see the rider's live phone number, or route calls through a proxy?
--  2. Are there admins in-app at all yet, or is review done only via the backend
--     service with the service_role key? (affects whether 'admin' policies matter now)
--  3. Can a rider decline / release an accepted job back to 'pending'? (affects
--     deliveries_update transitions)
-- ============================================================================
