# Phase 1 Verification Report

Status of the Doctor Appointment Booking App after all 16 Phase 1 tasks were
implemented, deployed, and smoke-tested against the **real Firebase project**
(`doctor-appointment-booki-fc9d6`).

- **Local verification:** `flutter analyze` clean · **221/221 tests pass**
- **Deployed:** Firestore rules + composite index · Firebase Hosting (doctor
  photos + CORS) · seeded catalog (8 doctors, 768 slots)
- **Smoke test:** Parts A (app flows), B (rules matrix), C (photos) — all green
- **Bugs found by the smoke test:** 2 production bugs, both fixed and verified
  (see [Bugs found](#bugs-found))

---

## Environment & deployed state

| Artifact | State |
|---|---|
| Project | `doctor-appointment-booki-fc9d6` (Firebase, Spark plan — no billing) |
| `firestore.rules` | Level 1 rules deployed (catalog public-read, own-appointments, `isBooked`-only slot flips) |
| `firestore.indexes.json` | `slots (doctorId ASC, startTime ASC)` composite index deployed |
| Firebase Hosting | `https://doctor-appointment-booki-fc9d6.web.app` — `doctor-photos/` + `Access-Control-Allow-Origin: *` |
| Seed data | 8 doctors · 768 slots (14 days, Mon–Sat, 09:00–17:00) · photos on Hosting |
| Auth | Email/password, two smoke accounts created during testing |

Relevant branches (all merged to `master` unless noted):

- Phase 1 tasks 1–16 → merged fast-forward to `master` (`1a9aebd`)
- Photos on Hosting instead of Storage → `3d4632c`
- Smoke-test fixes (CORS + router redirect) → `2af8f82`
- Rules smoke tool → `tool/rules-smoke` (not yet merged)
- This report → `docs/verification-report` (not yet merged)

---

## Part A — app flows (live, against the real backend)

Driven through the real Flutter web app (`flutter run -d web-server`) with two
accounts (Patient A, Patient B). Every flow verified both in the UI **and** by
reading the resulting Firestore state with the admin SDK.

| # | Flow | Result | Backend evidence |
|---|---|---|---|
| A1 | Browse doctors | ✅ | 8 doctors; avatars render from Hosting (after fix #1) |
| A2 | Doctor profile | ✅ | Name, specialty, rating, about, clinic |
| A3 | Slot selection | ✅ | Sundays empty; grid loads — **composite index works** (no missing-index error) |
| A4 | Book slot | ✅ | Appointment doc `scheduled`; slot `isBooked: true` |
| A5 | Appointments → Upcoming | ✅ | Own appointment listed (own-read rule) |
| A6 | Cancel | ✅ | `status: cancelled` + `cancelledAt`; **slot freed** (`isBooked: false`) |
| A7 | Reschedule | ✅ | Old slot freed, new slot booked, appointment re-pointed atomically (after fix #2) |
| A8 | Slot race | ✅* | Booked slot hidden from the second user's grid (SlotPolicy pre-check); the transaction-level double-book abort is covered by automated fake tests |
| A9 | Cross-patient privacy | ✅ | B sees only B's appointments — no leaks |

Final backend state after the smoke test: 3 appointments (2 scheduled, 1
cancelled) and exactly 2 booked slots — no orphans.

\* A true two-device race can't be produced in a single browser window because
the second user never sees the booked slot to confirm on; the optimistic-
concurrency abort was verified in the Task 12/14 fake-transaction tests.

## Part B — rules matrix (16 checks, then 15 as the committed tool)

The B1–B9 negative matrix, exercised against the **deployed rules** with real
ID tokens via the Firestore REST API (rules are evaluated server-side, same as
a client). Also re-runnable: `tool/rules-smoke/rules_smoke.mjs`.

| Scenario | Expected | Got |
|---|---|---|
| B1 read `doctors` / B1b `slots` (no auth) | allowed | 200 ✅ |
| B2 create `doctors` (authed) | denied | 403 ✅ |
| B3 update `slots` changing `startTime` | denied | 403 ✅ |
| B4a/b `isBooked` flips (authed, then restored) | allowed | 200 ✅ |
| B4c `isBooked` flip (no auth) | denied | 403 ✅ |
| B5 create appointment for another patient | denied | 403 ✅ |
| B6 create appointment, `doctorId` ≠ slot's (`get()` join) | denied | 403 ✅ |
| B7 create own matching appointment | allowed | 200 ✅ |
| B8a read owner's appointment as attacker | denied | 403 ✅ |
| B8b read as owner / B8c no auth | allowed / denied | 200 / 403 ✅ |
| B9a update transferring `patientId` | denied | 403 ✅ |
| B9b delete own appointment | denied | 403 ✅ |

Key proofs: the `get()`-join prevents fabricated appointments; ownership holds
before *and* after updates (no transfer); the `isBooked`-only slot rule works
as designed; catalog writes are impossible.

## Part C — photos

Doctor photos are static files on free Firebase Hosting (Storage needs Blaze
for new projects). Verified: photo URLs return HTTP 200, the browser loads them
as XHR (200) after the CORS fix, and avatars render in the app.

---

## Bugs found

Two production bugs surfaced by the smoke test. Both were real, both are fixed,
each has a regression test, and both fixes are verified live.

### Bug 1 — Web avatars broken by CORS

- **Symptom:** every doctor avatar fell back to initials in the web app.
- **Root cause:** Flutter web loads images via XHR, which enforces CORS.
  Firebase Hosting sends no `Access-Control-Allow-Origin` by default, so all 8
  photo fetches were blocked (network log: `ERR_FAILED` + CORS policy error).
- **Fix:** hosting response header in `firebase.json` — `Access-Control-Allow-Origin: *` for `/doctor-photos/**`; redeployed.
- **Verified:** photo requests return 200 (XHR), avatars render. Native builds were never affected.

### Bug 2 — Reschedule confirm → "Route not found"

- **Symptom:** tapping **Reschedule** on the confirm step landed on the router's
  error page — in production the reschedule flow was completely broken.
- **Root cause:** (1) the `reschedule` route's redirect only accepted a bare
  `Appointment` extra, but the confirm push passes a `(Appointment, TimeSlot)`
  record, so the redirect fired; (2) GoRouter 17 parses a relative redirect
  string like `'..'` as the literal location `'/..'` (confirmed in the package
  source: `normalizeUri` prepends `/`), which matches no route → error page.
  All three defensive redirects (`'..'`, `'..'`, `'../book'`) were affected.
- **Fix:** absolute redirect targets everywhere, and the `reschedule` route now
  accepts both extra shapes. Added a router-level regression test driving the
  full flow (appointments → reschedule → pick slot → confirm).
- **Verified:** widget test + live app land on "Appointment rescheduled!", with
  the atomic triple confirmed in Firestore.

---

## Re-verification checklist

```bash
# Local
flutter analyze
flutter test                       # 221/221 expected

# Deploy (after any rules/photo change)
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only hosting

# Rules smoke (Part B) — needs two test users + one appointment + a free slot
RULES_SMOKE_OWNER_EMAIL=... RULES_SMOKE_OWNER_PASSWORD=... \
RULES_SMOKE_OWNER_APPOINTMENT_ID=... RULES_SMOKE_ATTACKER_EMAIL=... \
RULES_SMOKE_ATTACKER_PASSWORD=... RULES_SMOKE_SLOT_ID=... \
node tool/rules-smoke/rules_smoke.mjs   # 15 passed, 0 failed expected
```

## Outstanding you-steps

- Nothing blocks Phase 1. The manual-smoke checklist is fully executed (Parts
  A/B/C all green).
- Optional cleanup: delete the smoke accounts (`smoke.a@example.com`,
  `smoke.b@example.com` — passwords are ephemeral, set per-run via the tool's
  env vars) and un-book the two test slots to leave the dev project pristine.
- `master` is 15 commits ahead of `origin/master` — nothing pushed.
