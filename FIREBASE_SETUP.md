# Firebase Setup Guide — Fixing Firestore Permission Errors

## Problem

You are seeing:
```
[cloud_firestore/permission-denied] The caller does not have permission 
to execute the specified operation.
```

This happens when your **Firebase Firestore Security Rules** are too restrictive and block the app's read/write operations.

---

## Solution: Deploy Firestore Rules

### Step 1: Install Firebase CLI

If you haven't installed it yet, run:

```bash
npm install -g firebase-tools
```

Or using Yarn:

```bash
yarn global add firebase-tools
```

---

### Step 2: Login to Firebase

```bash
firebase login
```

This opens a browser window. Sign in with the Google account that owns your Firebase project (`dispatch-rider-2fb16-b28e7`).

---

### Step 3: Initialize Firebase in Your Project

From your project root (`dispatch_rider_new`), run:

```bash
firebase init
```

When prompted:

| Prompt | Select |
|--------|--------|
| Which Firebase CLI features? | ✅ **Firestore** |
| Use an existing project? | ✅ **Yes** → Select `dispatch-rider-2fb16-b28e7` |
| Firestore rules file? | `firestore.rules` (already created) |
| Firestore indexes file? | Press Enter to accept default |

---

### Step 4: Deploy the Rules

```bash
firebase deploy --only firestore:rules
```

You should see:
```
✔  firestore: released rules firestore.rules to cloud.firestore
```

---

## What the Rules Allow

The `firestore.rules` file in this project allows:

| Collection | Read | Write | Notes |
|------------|------|-------|-------|
| `users/{userId}` | ✅ Auth + own UID | ✅ Auth + own UID | Profile access |
| `deliveries/{id}` | ✅ Any authenticated user | ✅ Any authenticated user (create) | Riders read pending; clients create |
| `deliveries/{id}` | — | ✅ Update by client/rider only | Only assigned parties can update |
| `riders/{riderId}` | ✅ Auth + own UID | ✅ Auth + own UID | FCM token storage |
| `clients/{clientId}` | ✅ Auth + own UID | ✅ Auth + own UID | FCM token storage |
| `locations/{id}` | ✅ Any authenticated user | ✅ Any authenticated user | Location tracking |

---

## Alternative: Set Rules in Firebase Console (Quick Fix)

If you can't install the CLI, do this in the browser:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `dispatch-rider-2fb16-b28e7`
3. Navigate to **Firestore Database** → **Rules**
4. Replace the default `allow read, write: if false;` with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

⚠️ **Warning**: The above allows any authenticated user to access everything. Use the `firestore.rules` file from this project for production-grade security.

5. Click **Publish**

---

## Verify It's Working

After deploying rules, restart your app and test:

1. **Register as a rider** — Should now save to Firestore without error
2. **Tap "Pending Deliveries"** — Should now show delivery list (or "No pending deliveries" if empty)

---

## Project Info

| Key | Value |
|-----|-------|
| Firebase Project ID | `dispatch-rider-2fb16-b28e7` |
| Rules File | `firestore.rules` |
| Android App ID | `1:691295757862:android:1c8c406cd522a7880228e7` |

---

## Troubleshooting

### "Command not found: firebase"
```bash
# Windows (PowerShell)
npm install -g firebase-tools

# Or check your PATH
```

### "Project not found"
Make sure you're logged in with the correct Google account:
```bash
firebase logout
firebase login
```

### Rules still not working after deploy
- Wait 1-2 minutes for rules to propagate
- Hot-restart the Flutter app (not just hot-reload)
- Check the Firebase Console Rules tab to confirm deployment
