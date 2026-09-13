-- ============================================================================
-- Dispatch Rider — reshape rider_verifications to match the actual UI
-- Applied 2026-09-13 to project bvztrnekmjaulwsjymcc.
--
-- 0001_schema.sql modeled rider_verifications on the ORIGINAL Firebase-era
-- form (nin, address, proof-of-address IMAGE, selfie IMAGE, full_name). The
-- redesigned rider_verification_screen.dart collects different fields: NIN,
-- address, a proof-of-address TEXT field, full name, next-of-kin name/phone/
-- relationship, and a single document image (no selfie). Reshaping now while
-- the table has 0 rows.
-- ============================================================================
alter table public.rider_verifications
  rename column proof_url to document_url;
alter table public.rider_verifications
  drop column selfie_url;
alter table public.rider_verifications
  add column proof_of_address text,
  add column next_of_kin text,
  add column next_of_kin_phone text,
  add column next_of_kin_relationship text;
