-- ============================================================================
-- Dispatch Rider — post-apply security hardening (Phase 2)
-- Applied 2026-09-13 to project bvztrnekmjaulwsjymcc, in response to
-- `get_advisors` findings surfaced immediately after 0001-0003 were applied.
-- ============================================================================

-- Harden trigger functions: explicit search_path (lint: function_search_path_mutable)
create or replace function public.set_updated_at() returns trigger
language plpgsql set search_path = public as $$
begin new.updated_at := now(); return new; end $$;

create or replace function public.enforce_delivery_transition() returns trigger
language plpgsql set search_path = public as $$
begin
  if old.status = new.status then
    return new;
  end if;

  if old.status = 'pending' and new.status = 'accepted' then
    if new.rider_id is null then
      raise exception 'accepting a delivery requires rider_id';
    end if;
    new.accepted_at := now();

  elsif old.status = 'accepted' and new.status = 'picked_up' then
    null;

  elsif old.status = 'picked_up' and new.status = 'in_transit' then
    null;

  elsif old.status = 'in_transit' and new.status = 'completed' then
    new.completed_at := now();

  elsif old.status = 'accepted' and new.status = 'pending' then
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

-- Trigger functions are not part of the public API — revoke direct RPC execution.
revoke execute on function public.set_updated_at() from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- apply_rider_rating is meant to be called ONLY by the trusted backend service
-- (service_role), never directly by an end user — otherwise any authenticated
-- user could inflate/deflate any rider's rating via PostgREST RPC.
revoke execute on function public.apply_rider_rating(uuid, numeric) from public, anon, authenticated;
grant execute on function public.apply_rider_rating(uuid, numeric) to service_role;

-- join_company is meant to be self-service for a signed-in user only.
revoke execute on function public.join_company(text) from public, anon;

-- ============================================================================
-- KNOWN REMAINING ADVISOR FINDINGS — deliberately left as-is, surfaced here
-- rather than auto-fixed (per Supabase advisor guidance: don't blind-apply
-- remediation that can change access behavior without a human decision):
--
-- 1. ERROR — public.spatial_ref_sys has RLS disabled.
--    This table is created BY THE POSTGIS EXTENSION ITSELF — ~8,500 rows of
--    public EPSG spatial-reference-system definitions (no user data, no
--    secrets). It is standard on every PostGIS install and Postgres/PostGIS
--    tooling expects to be able to read it without auth. Enabling RLS without
--    an explicit "allow read to everyone" policy would break geography
--    operations for both anon and authenticated roles (per Supabase's own
--    warning: "enabling RLS without policies will block all access").
--    If you want to silence the advisory, this is the safe remediation:
--      ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY;
--      CREATE POLICY spatial_ref_sys_read_all ON public.spatial_ref_sys
--        FOR SELECT TO anon, authenticated USING (true);
--    Not applied — ask before running, since it changes access rules on a
--    system table.
--
-- 2. WARN — extension `postgis` is installed in the `public` schema instead of
--    a dedicated `extensions` schema. PostGIS does not support
--    `ALTER EXTENSION ... SET SCHEMA` (confirmed by a failed attempt in this
--    session), so fixing this cleanly requires `DROP EXTENSION postgis CASCADE`
--    (which drops profiles.last_geog / deliveries.pickup_geog and their GIST
--    indexes) followed by `CREATE EXTENSION postgis SCHEMA extensions` and
--    recreating those generated columns + indexes. Safe to do now (0 rows in
--    every table) but NOT done automatically — this is a schema-shape change,
--    not a pure hardening fix. Revisit if it matters before real data lands.
--
-- 3. WARN — `st_estimatedextent(...)` (3 overloads) executable by anon/
--    authenticated. This is a stock PostGIS built-in function, not something
--    this project defined; not touched.
--
-- 4. WARN — `current_company_id()`, `current_role()`, `join_company(text)`
--    still listed as SECURITY DEFINER + authenticated-executable. This is
--    INTENTIONAL: they are self-service helpers a signed-in user is meant to
--    call directly (they only ever act on `auth.uid()`, never an arbitrary
--    id), which is exactly why RLS policies in 0002 call them. No fix needed.
-- ============================================================================
