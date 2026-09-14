-- ============================================================================
-- Dispatch Rider — support functions/columns for the backend service
-- Applied 2026-09-13 to project bvztrnekmjaulwsjymcc.
-- ============================================================================

-- Prevents a client from rating the same delivery twice via the backend's
-- /deliveries/:id/rating endpoint.
alter table public.deliveries
  add column rating_submitted boolean not null default false;

-- Rider matching: called by the backend (service_role) in response to a
-- Database Webhook on `deliveries` INSERT. Runs the ST_DWithin/ST_Distance
-- query sketched in 0001_schema.sql's trailing comment.
create or replace function public.find_nearby_riders(
  p_delivery_id uuid,
  p_radius_m integer default 15000,
  p_limit integer default 5
) returns table(rider_id uuid, fcm_token text, distance_m double precision)
language sql stable security definer set search_path = public as $$
  select p.id, p.fcm_token, ST_Distance(p.last_geog, d.pickup_geog)
  from public.profiles p, public.deliveries d
  where d.id = p_delivery_id
    and p.role = 'rider'
    and p.is_online = true
    and p.company_id = d.company_id
    and p.fcm_token is not null
    and p.last_geog is not null
    and d.pickup_geog is not null
    and ST_DWithin(p.last_geog, d.pickup_geog, p_radius_m)
  order by ST_Distance(p.last_geog, d.pickup_geog) asc
  limit p_limit;
$$;

-- Only the backend (service_role) may run this — it returns other users'
-- fcm_token values, which must never be exposed to end users.
revoke execute on function public.find_nearby_riders(uuid, integer, integer)
  from public, anon, authenticated;
grant execute on function public.find_nearby_riders(uuid, integer, integer)
  to service_role;

-- Small helper the backend uses to fetch a delivery's client + rider tokens
-- for accept/complete notifications without hand-rolling joins each time.
create or replace function public.get_delivery_notify_targets(p_delivery_id uuid)
returns table(
  client_id uuid, client_token text,
  rider_id uuid, rider_token text
)
language sql stable security definer set search_path = public as $$
  select c.id, c.fcm_token, r.id, r.fcm_token
  from public.deliveries d
  join public.profiles c on c.id = d.client_id
  left join public.profiles r on r.id = d.rider_id
  where d.id = p_delivery_id;
$$;

revoke execute on function public.get_delivery_notify_targets(uuid)
  from public, anon, authenticated;
grant execute on function public.get_delivery_notify_targets(uuid) to service_role;
