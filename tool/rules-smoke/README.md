# Rules smoke (Part B of the security checklist)

Verifies the **deployed** [Firestore security rules](../../firestore.rules) by
exercising them with real user ID tokens through the Firestore REST API. The
rules engine runs server-side, so this is exactly what a client is allowed to
do — no admin-SDK bypass.

Re-run this after any change to `firestore.rules` + `firebase deploy --only
firestore:rules`.

## What it verifies (B1–B9)

| Check | Proves |
|---|---|
| B1 | `doctors`/`slots` are public-read (no auth) |
| B2 | `doctors` are never client-writable |
| B3 | `slots` reject any update beyond `isBooked` |
| B4 | `slots` allow authenticated `isBooked`-only flips; deny unauthenticated |
| B5 | `appointments` reject creation for another patient |
| B6 | `appointments` reject a `doctorId` that doesn't match the slot (the `get()` join) |
| B7 | `appointments` allow an own, matching creation |
| B8 | `appointments` are readable only by their owner |
| B9 | updates can't transfer ownership; deletes are denied |

## Prerequisites

- The project is deployed (rules live in Firestore) and **seeded**
  (`node tool/seed/index.js` then `firebase deploy`), so slot docs exist.
- Two test users, one with an existing appointment:
  - the **owner** — owns the appointment under test (B8/B9)
  - the **attacker** — a second account that performs the denied actions

## Run

Credentials come from environment variables so nothing secret is committed:

```bash
RULES_SMOKE_OWNER_EMAIL=patient.a@example.com \
RULES_SMOKE_OWNER_PASSWORD='...' \
RULES_SMOKE_OWNER_APPOINTMENT_ID=<appointment doc id> \
RULES_SMOKE_ATTACKER_EMAIL=patient.b@example.com \
RULES_SMOKE_ATTACKER_PASSWORD='...' \
RULES_SMOKE_SLOT_ID=<a free slot doc id, e.g. dr-ana-patel__2026-08-13T06-00-00-000Z> \
node tool/rules-smoke/rules_smoke.mjs
```

The project id and web API key are read from `.firebaserc` and
`lib/firebase_options.dart` automatically (override the project with
`FIREBASE_PROJECT_ID`).

Expected output: **15 passed, 0 failed** (B1–B9 plus extra unauthenticated
variants).

## Side effects & cleanup

- B4 temporarily flips the slot's `isBooked` and restores it.
- B7 creates one appointment doc named `rules-smoke-<timestamp>` per run —
  rules forbid client-side deletes, so remove `rules-smoke-*` docs from the
  console (or via the admin SDK) when done testing.
