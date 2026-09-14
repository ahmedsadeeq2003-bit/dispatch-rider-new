-- ============================================================================
-- Dispatch Rider — allow accepted -> completed directly
-- Applied 2026-09-13 to project bvztrnekmjaulwsjymcc.
--
-- The real app's "Complete" button (active_deliveries_screen.dart) jumps
-- straight from accepted -> completed. picked_up/in_transit exist as display
-- labels (StatusBadge, TrackOrderScreen's OrderStep enum) but nothing in the
-- current UI actually writes those statuses. Widen the trigger so the real
-- write path works, while still keeping the granular chain available for
-- when/if the app grows a pickup-confirmation step.
-- ============================================================================
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

  elsif old.status in ('accepted', 'picked_up', 'in_transit') and new.status = 'completed' then
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
