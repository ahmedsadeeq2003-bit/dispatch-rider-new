# TODO_TENANCY (Multi-company / Rental)

- [x] Add `companyId` to `users` and `deliveries` documents (schema + code) - plan created (implementation next)

- [ ] Add `companies/{companyId}` collection (branding + plan)
- [ ] Update `lib/services/auth_service.dart` to accept/join a company and persist `companyId`
- [ ] Update `lib/services/delivery_service.dart`:
  - [ ] create delivery with `companyId`
  - [ ] all queries/writes filtered by `companyId`
  - [ ] rider notification only within same `companyId`
- [ ] Update `lib/services/location_tracking_service.dart`:
  - [ ] enforce tenant scoping when writing `locationUpdates` and updating rider location
- [ ] Replace `CompletedDeliveriesScreen` mock with Firestore query filtered by `companyId`
- [ ] Update all delivery screens (active/pending/track/confirm/dispatch) to use tenant-scoped service methods
- [ ] Update `firestore.rules` for strict tenant isolation
- [ ] Smoke test end-to-end: company A dispatch -> riders in A can accept -> company B cannot see

