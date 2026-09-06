# TODO (Multi-company / Rental)

- [x] Step 1: Add `companies` collection + `companyId` fields to `users` and `deliveries` (+ optional `locationUpdates` handling)

- [ ] Step 2: Update `AuthService` to capture/set `companyId` during register/login and keep it available in app
- [ ] Step 3: Update `DeliveryService` to write/read tenant-scoped deliveries and filter rider matching/queries by `companyId`
- [ ] Step 4: Update `LocationTrackingService` to ensure location updates are written/allowed only within same company
- [ ] Step 5: Update all delivery-related screens to use updated tenant-scoped service methods
- [ ] Step 6: Replace mocked `CompletedDeliveriesScreen` with Firestore-backed implementation
- [ ] Step 7: Update Firestore security rules for strict tenant isolation (`companyId` checks)
- [x] Step 8: Add minimal UI flow to select/join a company (invite code) and persist selection (placeholder)

- [ ] Step 9: Smoke test: create company, register client/rider, dispatch delivery, accept, track live, complete

