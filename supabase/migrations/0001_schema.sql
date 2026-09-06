-- ============================================================================
-- Dispatch Rider — Supabase schema (Phase 1 DESIGN — not yet applied)
-- Target: PostgreSQL 17 (Supabase)
-- Review before running. Apply via `supabase db push` / migration in Phase 2.
-- ============================================================================

-- Extensions -----------------------------------------------------------------
create extension if not exists "pgcrypto";      -- gen_random_uuid()
-- create extension if not exists "postgis";     -- OPTIONAL: spatial rider matching (see notes)

-- Enums ---------------------------------------------------------------------
create type user_role          as enum ('client', 'rider', 'admin');
create type delivery_status    as enum ('pending', 'accepted', 'picked_up', 'in_transit', 'completed', 'cancelled');
create type payment_method     as enum ('cash', 'card');
create type verification_status as enum ('pending', 'approved', 'rejected');

-- ---------------------------------------------------------------------------
-- companies
-- ---------------------------------------------------------------------------
create table public.companies (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,                 -- invite code, e.g. 'DEFAULT'
  name        text not null,
  plan        text not null default 'free',
  status      text not null default 'active',
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- profiles  (1:1 with auth.users — email/phone-confirm live in auth.users)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id                uuid primary key references auth.users(id) on delete cascade,
  firebase_uid      text unique,                    -- migration bridge only; drop after cutover
  role              user_role not null default 'client',
  full_name         text,
  phone_number      text,
  company_id        uuid references public.companies(id),
  rating            numeric(3,2) not null default 5.0,
  total_deliveries  integer not null default 0,
  total_ratings     numeric not null default 0,
  is_online         boolean not null default false,
  last_lat          double precision,
  last_lng          double precision,
  last_location_at  timestamptz,
  fcm_token         text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index profiles_company_role_online_idx on public.profiles (company_id, role, is_online);
create index profiles_last_loc_idx            on public.profiles (last_lat, last_lng);

-- ---------------------------------------------------------------------------
-- rider_verifications  (own table, not a JSON blob → cleaner RLS + admin review)
-- ---------------------------------------------------------------------------
create table public.rider_verifications (
  id            uuid primary key default gen_random_uuid(),
  rider_id      uuid not null unique references public.profiles(id) on delete cascade,
  nin           text not null,
  address       text not null,
  full_name     text not null,
  proof_url     text,          -- storage path in bucket 'rider-verification'
  selfie_url    text,
  status        verification_status not null default 'pending',
  submitted_at  timestamptz not null default now(),
  reviewed_at   timestamptz,
  reviewed_by   uuid references public.profiles(id)
);

-- ---------------------------------------------------------------------------
-- deliveries
-- ---------------------------------------------------------------------------
create table public.deliveries (
  id              uuid primary key default gen_random_uuid(),
  company_id      uuid not null references public.companies(id),
  client_id       uuid not null references public.profiles(id),
  rider_id        uuid references public.profiles(id),
  pickup_address  text not null,
  dropoff_address text not null,
  pickup_lat      double precision,
  pickup_lng      double precision,
  dropoff_lat     double precision,
  dropoff_lng     double precision,
  weight_kg       numeric not null,
  package_type    text not null,
  price_naira     numeric not null,
  payment_method  payment_method not null default 'cash',
  status          delivery_status not null default 'pending',
  created_at      timestamptz not null default now(),
  accepted_at     timestamptz,
  completed_at    timestamptz,
  cancelled_at    timestamptz
);
create index deliveries_company_status_created_idx on public.deliveries (company_id, status, created_at desc);
create index deliveries_rider_status_accepted_idx  on public.deliveries (rider_id, status, accepted_at desc);
create index deliveries_rider_status_completed_idx on public.deliveries (rider_id, status, completed_at desc);
create index deliveries_client_created_idx         on public.deliveries (client_id, created_at desc);

-- ---------------------------------------------------------------------------
-- delivery_locations  (rider breadcrumb trail; was deliveries/*/locationUpdates)
-- ---------------------------------------------------------------------------
create table public.delivery_locations (
  id           bigint generated always as identity primary key,
  delivery_id  uuid not null references public.deliveries(id) on delete cascade,
  rider_id     uuid not null references public.profiles(id),
  lat          double precision not null,
  lng          double precision not null,
  speed        numeric,
  accuracy     numeric,
  recorded_at  timestamptz not null default now()
);
create index delivery_locations_delivery_time_idx on public.delivery_locations (delivery_id, recorded_at desc);

-- ---------------------------------------------------------------------------
-- Triggers & functions
-- ---------------------------------------------------------------------------

-- updated_at maintenance
create or replace function public.set_updated_at() returns trigger
language plpgsql as $$
begin new.updated_at := now(); return new; end $$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- auto-create a profile row when an auth user is created.
-- role / company_id / names come from sign-up metadata (raw_user_meta_data).
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_company uuid;
begin
  if (new.raw_user_meta_data ? 'company_code') then
    select id into v_company from public.companies
      where code = (new.raw_user_meta_data->>'company_code');
  end if;

  insert into public.profiles (id, role, full_name, phone_number, company_id, firebase_uid)
  values (
    new.id,
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'client'),
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'phone_number',
    v_company,
    new.raw_user_meta_data->>'firebase_uid'
  );
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- helper: current user's company (STABLE, SECURITY DEFINER → avoids RLS recursion)
create or replace function public.current_company_id() returns uuid
language sql stable security definer set search_path = public as $$
  select company_id from public.profiles where id = auth.uid()
$$;

create or replace function public.current_role() returns user_role
language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid()
$$;

-- join a company by invite code (pre-membership lookup without opening companies to all)
create or replace function public.join_company(p_code text) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_company uuid;
begin
  select id into v_company from public.companies where code = p_code and status = 'active';
  if v_company is null then raise exception 'invalid company code'; end if;
  update public.profiles set company_id = v_company where id = auth.uid();
  return v_company;
end $$;

-- apply a rating after a delivery completes (called by backend service / RPC)
create or replace function public.apply_rider_rating(p_rider uuid, p_stars numeric) returns void
language plpgsql security definer set search_path = public as $$
begin
  update public.profiles
     set total_ratings    = total_ratings + p_stars,
         total_deliveries = total_deliveries + 1,
         rating           = round((total_ratings + p_stars) / (total_deliveries + 1), 2)
   where id = p_rider;
end $$;

-- ---------------------------------------------------------------------------
-- Realtime: expose tables the app subscribes to
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table public.deliveries;
alter publication supabase_realtime add table public.delivery_locations;

-- ============================================================================
-- NOTES
-- - PostGIS: if spatial rider-matching is wanted, add `postgis`, a generated
--   `geography(Point,4326)` column on profiles/deliveries, a GIST index, and let
--   the BACKEND service use ST_DWithin. The Flutter client keeps sending plain
--   lat/lng, so no client change. Deferred out of this baseline for simplicity.
-- - Firebase `users` doc fields not carried over: `companyCode` (redundant with
--   company_id), `lastUpdated` (→ updated_at). `verification` map → rider_verifications.
-- - Firestore auto-id strings become uuids; `firebase_uid` bridges the data load.
-- ============================================================================
