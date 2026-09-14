-- ============================================================================
-- Dispatch Rider — delivery state machine + in-app admin role (Phase 1 DESIGN)
-- Resolves open questions §7.2 (admin surface) and §7.3 (state machine).
-- NOT yet applied.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Delivery state machine
--
-- pending ──(rider claims)──▶ accepted ──(rider)──▶ picked_up ──(rider)──▶ in_transit ──(rider)──▶ completed
--    │                           │
--    │                           └──(rider releases, before pickup)──▶ pending   [released_count++, rider_id cleared]
--    │
--    └──(client, with cancel_reason)──▶ cancelled     accepted ──(client, with cancel_reason)──▶ cancelled
--
-- Anything else is rejected. Enforced in one BEFORE UPDATE trigger so app code
-- and the backend service share the same guarantees regardless of who writes.
-- ---------------------------------------------------------------------------
create or replace function public.enforce_delivery_transition() returns trigger
language plpgsql as $$
begin
  -- no-op updates (e.g. touching unrelated columns) are always fine
  if old.status = new.status then
    return new;
  end if;

  if old.status = 'pending' and new.status = 'accepted' then
    if new.rider_id is null then
      raise exception 'accepting a delivery requires rider_id';
    end if;
    new.accepted_at := now();

  elsif old.status = 'accepted' and new.status = 'picked_up' then
    null; -- no extra bookkeeping

  elsif old.status = 'picked_up' and new.status = 'in_transit' then
    null;

  elsif old.status = 'in_transit' and new.status = 'completed' then
    new.completed_at := now();

  elsif old.status = 'accepted' and new.status = 'pending' then
    -- rider releasing the job back to the pool
    if new.rider_id is not null then
      raise exception 'releasing a delivery must clear rider_id';
    end if;
    new.released_count := old.released_count + 1;
    new.accepted_at := null;

  elsif old.status in ('pending', 'accepted') and new.status = 'cancelled' then
    if new.cancel_reason is null or length(trim(new.cancel_reason)) = 0 then
      raise exception 'cancelling a delivery requires cancel_reason';
    end if;
    new.cancelled_at := now();

  else
    raise exception 'illegal delivery status transition: % -> %', old.status, new.status;
  end if;

  return new;
end $$;

create trigger deliveries_enforce_transition
  before update on public.deliveries
  for each row execute function public.enforce_delivery_transition();

-- ---------------------------------------------------------------------------
-- In-app admin role — RLS additions
-- (profiles_select_admin / rv_admin_all / deliveries_select_admin already
--  exist in 0002_policies.sql; these add the missing write-side + companies.)
-- ---------------------------------------------------------------------------

-- companies: admins can create/manage; everyone else stays read-only-own (0002)
create policy companies_admin_all on public.companies
  for all to authenticated
  using (public.current_role() = 'admin')
  with check (public.current_role() = 'admin');

-- profiles: admin can update ANY profile (promote/demote role, fix company_id,
-- deactivate a rider). Kept separate from profiles_update_self so a compromised
-- user account still can't self-promote (that policy's WITH CHECK still blocks
-- role/company_id changes for non-admins).
create policy profiles_admin_update_any on public.profiles
  for update to authenticated
  using (public.current_role() = 'admin')
  with check (public.current_role() = 'admin');

-- deliveries: admin can update any row (e.g. force-cancel, reassign) —
-- selects already covered by deliveries_select_admin in 0002.
create policy deliveries_admin_update on public.deliveries
  for update to authenticated
  using (public.current_role() = 'admin')
  with check (public.current_role() = 'admin');

-- ---------------------------------------------------------------------------
-- Bootstrapping the FIRST admin
-- There is deliberately no self-service "become admin" path. Promote the first
-- admin by hand once, from the Supabase SQL editor (service_role context):
--
--   update public.profiles set role = 'admin' where id = '<uuid-of-that-user>';
--
-- Every subsequent admin can then be promoted from the in-app admin screen
-- (which calls the same UPDATE, now allowed by profiles_admin_update_any).
-- ---------------------------------------------------------------------------
