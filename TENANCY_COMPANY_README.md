# Tenancy / Multi-company Rental - Implementation Notes

This repo currently does **not** yet implement multi-tenant scoping.

## Required end-to-end changes
1. Firestore schema:
   - Add `companyId` to `users/{uid}` and `deliveries/{deliveryId}`.
   - Add `companies/{companyId}`.
   - Optionally add `companyId` into `deliveries/{deliveryId}/locationUpdates/{id}` documents, or infer via parent delivery.

2. App state:
   - During register/login, user must be associated with a `companyId`.
   - The simplest approach for now is an **invite code** UI field.

3. Code:
   - All Firestore queries must include `companyId`.
   - All writes must set `companyId`.

4. Security rules:
   - Enforce `companyId` isolation for all reads/writes.

## Current status in this branch
- Plans were updated in `TODO.md` and `TODO_TENANCY.md`.
- No tenant logic has been implemented yet.

