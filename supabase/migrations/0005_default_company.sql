-- ============================================================================
-- Dispatch Rider — default company for the current (tenancy-descoped) UI
-- Applied 2026-09-13 to project bvztrnekmjaulwsjymcc.
--
-- The redesigned Flutter screens (welcome/login/register/rider register) no
-- longer collect a company invite code — that flow was descoped when the UI
-- was redone. The schema stays multi-tenant-ready (deliveries.company_id is
-- NOT NULL), so every signup is assigned a 'DEFAULT' company unless sign-up
-- metadata explicitly supplies a company_code. This mirrors the old Firebase
-- seed-script's behavior (seed-script/seed.js created the same 'DEFAULT' row).
-- ============================================================================

insert into public.companies (code, name, plan, status)
values ('DEFAULT', 'Default Company', 'free', 'active')
on conflict (code) do nothing;

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_company uuid;
  v_code text;
begin
  v_code := coalesce(new.raw_user_meta_data->>'company_code', 'DEFAULT');
  select id into v_company from public.companies where code = v_code;

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

revoke execute on function public.handle_new_user() from public, anon, authenticated;
