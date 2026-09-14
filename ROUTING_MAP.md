# Dispatch Rider App — Screen & Routing Map

> Last updated after test fixes. This document maps every screen, route, and interactive element.

---

## Route Registry (`lib/main.dart`)

| Route Path | Screen Widget | Role |
|-----------|---------------|------|
| `/` | `WelcomeScreen` | Entry point — choose Login / Sign Up / Rider |
| `/login` | `LoginScreen` | Client login |
| `/register` | `RegisterScreen` | Client registration |
| `/dashboard` | `DashboardScreen` | Client dashboard after login |
| `/dispatch` | `DispatchOrderScreen` | Create a new delivery order |
| `/confirmdelivery` | `ConfirmDeliveryScreen` | Confirm order & request rider |
| `/trackorder` | `TrackOrderScreen` | Live map tracking of a delivery |
| `/activedeliveries` | `ActiveDeliveriesScreen` | List of client's active deliveries |
| `/completed-deliveries` | `CompletedDeliveriesScreen` | List of completed deliveries (mock data) |
| `/profile` | `ProfileScreen` | View user profile from Firestore |
| `/contact-us` | `ContactUsScreen` | Contact options (email, phone, WhatsApp) |
| `/rider` | `RiderAuthScreen` | Rider entry — Login or Register |
| `/rider-login` | `RiderLoginScreen` | Rider login |
| `/rider-register` | `RiderRegisterScreen` | Rider registration |
| `/rider-verification` | `RiderVerificationScreen` | Submit NIN, address, documents |
| `/rider-dashboard` | `RiderDashboardScreen` | Rider home after auth |
| `/riderdetails` | `RiderDetailsScreen` | Shows assigned rider info |
| `/pending-deliveries` | `PendingDeliveriesScreen` | Rider view — accept/decline orders |

---

## Detailed Screen Breakdown

### 1. WelcomeScreen (`/`)

| Element | Type | Action |
|---------|------|--------|
| "Login" | `ElevatedButton` | `Navigator.pushNamed(context, '/login')` |
| "Sign Up" | `TextButton` | `Navigator.pushNamed(context, '/register')` |
| "Rider" | `OutlinedButton` | `Navigator.pushNamed(context, '/rider')` |
| "English" | `OutlinedButton` | No-op (`onPressed: () {}`) |

---

### 2. LoginScreen (`/login`)

| Element | Type | Action |
|---------|------|--------|
| "Login" | `ElevatedButton` | Calls `AuthService.loginUser()` → on success `pushReplacementNamed('/dashboard')` |
| "Register" | `GestureDetector` (text) | `Navigator.pushNamed(context, '/register')` |

---

### 3. RegisterScreen (`/register`)

| Element | Type | Action |
|---------|------|--------|
| "Register" | `ElevatedButton` | Calls `AuthService.registerUser()` → on success `pushReplacementNamed('/dashboard')` |
| "Login" | `GestureDetector` (text) | `Navigator.pushNamed(context, '/login')` |

---

### 4. DashboardScreen (`/dashboard`)

**AppBar PopupMenu** (top-right `Icons.more_vert`):

| Menu Item | Value | Action |
|-----------|-------|--------|
| Profile | `profile` | `Navigator.pushNamed(context, '/profile')` |
| My Deliveries | `my_deliveries` | `Navigator.pushNamed(context, '/activedeliveries')` |
| Contact Us | `contact_us` | `Navigator.pushNamed(context, '/contact-us')` |
| Settings | `settings` | SnackBar: "Settings coming soon!" |
| Logout | `logout` | Shows logout dialog → `AuthService().signOut(context)` |

**Dashboard Cards:**

| Card | Color | onTap Action |
|------|-------|--------------|
| Dispatch | Deep Purple | `Navigator.pushNamed(context, '/dispatch')` |
| Track Order | Orange | `Navigator.pushNamed(context, '/trackorder')` |
| Active Deliveries | Green | `Navigator.pushNamed(context, '/activedeliveries')` |
| Completed | Blue | `Navigator.pushNamed(context, '/completed-deliveries')` |

---

### 5. DispatchOrderScreen (`/dispatch`)

| Element | Type | Action |
|---------|------|--------|
| "Pickup Location" | `TextField` | Typing triggers Nominatim API autocomplete |
| "Destination" | `TextField` | Typing triggers Nominatim API autocomplete |
| Suggestion items | `ListTile` | Tap selects location, stores lat/lon |
| "Confirm Order" | `ElevatedButton` | `Navigator.pushNamed(context, '/confirmdelivery', arguments: {...})` |

**Arguments passed to ConfirmDeliveryScreen:**
- `pickup` (String)
- `destination` (String)
- `pickupLatLng` (`LatLng?`)
- `destinationLatLng` (`LatLng?`)

---

### 6. ConfirmDeliveryScreen (`/confirmdelivery`)

| Element | Type | Action |
|---------|------|--------|
| "Cash" | `RadioListTile` | Sets `paymentMethod = 'cash'` |
| "Card" | `RadioListTile` | Sets `paymentMethod = 'card'` |
| "Confirm & Search for Rider" | `ElevatedButton` | Calls `DeliveryService.createDeliveryRequest()` → listens for `status == 'accepted'` → pushes `/riderdetails` |

**Navigation to RiderDetailsScreen (on rider accept):**
- Route: `/riderdetails`
- Arguments: `riderId`, `pickup`, `destination`, `package`, `price`, `weight`

---

### 7. RiderDetailsScreen (`/riderdetails`)

| Element | Type | Action |
|---------|------|--------|
| "Start Delivery" | `ElevatedButton` | **No-op** (`onPressed: () {}`) |
| "Cancel" | `OutlinedButton` | `Navigator.pop(context)` |

---

### 8. TrackOrderScreen (`/trackorder`)

| Element | Type | Action |
|---------|------|--------|
| "Call" | `ElevatedButton` | Launches phone dialer (`tel:+2348012345678`) |
| "Chat" | `OutlinedButton` | SnackBar: "Open chat (not implemented)" |
| "Cancel" | `OutlinedButton` | Shows cancel dialog → stops tracking → pops back |

**Note:** Also pushed via `MaterialPageRoute` from `ActiveDeliveriesScreen` with `orderId`, `pickup`, `destination`.

---

### 9. ActiveDeliveriesScreen (`/activedeliveries`)

| Element | Type | Action |
|---------|------|--------|
| "Track Live" | `ElevatedButton` | Pushes `TrackOrderScreen(orderId, pickupCoords, destCoords)` |
| "Complete" | `OutlinedButton` | Calls `DeliveryService.updateDeliveryStatus(deliveryId, 'completed')` |

---

### 10. CompletedDeliveriesScreen (`/completed-deliveries`)

- **Static screen** — displays mock completed delivery data
- No interactive navigation elements

---

### 11. ProfileScreen (`/profile`)

| Element | Type | Action |
|---------|------|--------|
| "Edit Profile" | `ElevatedButton` | SnackBar: "Edit profile coming soon!" |

---

### 12. ContactUsScreen (`/contact-us`)

| Element | Type | Action |
|---------|------|--------|
| Email card | `Card` (tap) | Launches `mailto:support@senditt.com` |
| Call card | `Card` (tap) | Launches `tel:+2348012345678` |
| WhatsApp card | `Card` (tap) | Launches `https://wa.me/2348012345678` |
| "Frequently Asked Questions" | `OutlinedButton` | SnackBar: "FAQ section coming soon!" |

---

### 13. RiderAuthScreen (`/rider`)

| Element | Type | Action |
|---------|------|--------|
| "Rider Login" | `ElevatedButton` | `Navigator.pushNamed(context, '/rider-dashboard')` |
| "Rider Register" | `OutlinedButton` | `Navigator.pushNamed(context, '/rider-register')` |

---

### 14. RiderLoginScreen (`/rider-login`)

| Element | Type | Action |
|---------|------|--------|
| "Login" | `ElevatedButton` | Calls `AuthService.loginRider()` |
| "Register" | `GestureDetector` (text) | `Navigator.pushNamed(context, '/rider-register')` |

---

### 15. RiderRegisterScreen (`/rider-register`)

| Element | Type | Action |
|---------|------|--------|
| "Register" | `ElevatedButton` | Calls `AuthService.registerRider()` |
| "Login" | `GestureDetector` (text) | `Navigator.pushNamed(context, '/rider-login')` |

---

### 16. RiderVerificationScreen (`/rider-verification`)

| Element | Type | Action |
|---------|------|--------|
| "Select Image" | `ElevatedButton` | Opens image picker from gallery |
| "Submit Verification" | `ElevatedButton` | Calls `AuthService.submitRiderVerification()` → on success `pushReplacementNamed('/rider-dashboard')` |

---


| Active Deliveries | Blue | `Navigator.pushNamed(context, '/activedeliveries')` |
| Completed Deliveries | Green | `Navigator.pushNamed(context, '/completed-deliveries')` |
| Rider Details | Purple | `Navigator.pushNamed(context, '/riderdetails', arguments: {...})` |

**FAB:**

| Element | Type | Action |
|---------|------|--------|
| `+` | `FloatingActionButton` | `Navigator.pushNamed(context, '/dispatch')` |

---

### 18. PendingDeliveriesScreen (`/pending-deliveries`)

| Element | Type | Action |
|---------|------|--------|
| "Accept" | `ElevatedButton` | Calls `DeliveryService.acceptDelivery(delivery.id, currentUser.uid)` → SnackBar → `Navigator.pushNamed(context, '/activedeliveries')` |
| "Decline" | `OutlinedButton` | SnackBar: "Declined delivery ..." |

---

## User Flow Diagrams

### Client Flow

```
WelcomeScreen (/)
    ├── Login ──────────────→ /login (LoginScreen)
    │                            └── Login Success ──→ /dashboard (replaces)
    ├── Sign Up ────────────→ /register (RegisterScreen)
    │                            └── Register Success ──→ /dashboard (replaces)
    └── Rider ──────────────→ /rider (RiderAuthScreen)
```

### Dashboard Navigation Tree

```
DashboardScreen (/dashboard)
    ├── PopupMenu: Profile ───────────────→ /profile
    ├── PopupMenu: My Deliveries ─────────→ /activedeliveries
    ├── PopupMenu: Contact Us ────────────→ /contact-us
    ├── PopupMenu: Settings ──────────────→ SnackBar (coming soon)
    ├── PopupMenu: Logout ────────────────→ AuthService.signOut()
    ├── Card: Dispatch ───────────────────→ /dispatch
    ├── Card: Track Order ────────────────→ /trackorder
    ├── Card: Active Deliveries ──────────→ /activedeliveries
    └── Card: Completed ──────────────────→ /completed-deliveries
```

### Rider Flow

```
RiderAuthScreen (/rider)
    ├── Rider Login ──────────────→ /rider-dashboard
    │                                  ├── Pending Deliveries ──→ /pending-deliveries
    │                                  │                              └── Accept ──→ /activedeliveries
    │                                  ├── Active Deliveries ───→ /activedeliveries
    │                                  ├── Completed Deliveries → /completed-deliveries
    │                                  ├── Rider Details ───────→ /riderdetails
    │                                  └── FAB (+) ─────────────→ /dispatch
    └── Rider Register ───────────→ /rider-register
                                       └── Register Success ──→ (verifies if needed) /rider-verification
                                                                   └── Submit ──→ /rider-dashboard
```

---

## Known Issues & TODOs

| Screen | Issue | Status |
|--------|-------|--------|
| `RiderDetailsScreen` | "Start Delivery" button has no action | Not implemented |
| `TrackOrderScreen` | "Chat" button shows "not implemented" SnackBar | Not implemented |
| `DashboardScreen` | "Settings" menu shows "coming soon!" SnackBar | Not implemented |
| `ProfileScreen` | "Edit Profile" shows "coming soon!" SnackBar | Not implemented |
| `ContactUsScreen` | "FAQ" shows "coming soon!" SnackBar | Not implemented |

---

## Test Coverage

| Test | Description |
|------|-------------|
| WelcomeScreen renders without error | Verifies "Senditt", tagline, and subtitle exist |
| WelcomeScreen has Login, Sign Up and Rider buttons | Verifies all 3 buttons are present |
| Login button navigates to /login | Taps Login, verifies route navigation |
| Sign Up button navigates to /register | Taps Sign Up, verifies route navigation |
| Rider button navigates to /rider | Scrolls Rider into view, taps, verifies navigation |

All tests pass: `flutter test` → **5/5 passed**.

