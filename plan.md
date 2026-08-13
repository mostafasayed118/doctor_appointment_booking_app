# Tasks: Doctor Appointment Booking App — MVP (Phase 1)

Each task follows the Section A contract (explain → plan → approve → implement → learning walkthrough). Logic tasks include tests. No commit/push without your explicit approval.

---

- [ ] **1. Project scaffold** — branch `feat/project-scaffold`
  - touches: `flutter create` output, `pubspec.yaml` (add stack deps: flutter_bloc, bloc, equatable, get_it, go_router, firebase_core, firebase_auth, cloud_firestore, firebase_storage, flutter_localizations, intl; dev: bloc_test, mocktail, fake_cloud_firestore), `analysis_options.yaml`, `lib/` folder skeleton (core/data/features/shared), delete default counter app
  - done when: `flutter pub get` clean, `flutter analyze` clean, `flutter test` passes (default smoke test), app builds on at least one platform

- [ ] **2. Core error handling** — branch `feat/core-error-handling`
  - touches: `lib/core/error/result.dart`, `lib/core/error/app_error.dart`, `lib/data/error/firebase_error_mapper.dart`
  - done when: unit tests pass for `Result<T>` (success/failure) and `FirebaseErrorMapper` (network/server/auth/slot-unavailable/not-found/unexpected mapping)

- [ ] **3. Core entities + SlotPolicy** — branch `feat/core-entities-slot-policy`
  - touches: `lib/core/entities/doctor.dart`, `time_slot.dart`, `appointment.dart`, `lib/core/utils/slot_policy.dart`
  - done when: unit tests pass for `SlotPolicy` (isInPast, canBook, owner-release rule) — pure Dart, no Firebase

- [ ] **4. DI + app bootstrap** — branch `feat/di-bootstrap`
  - touches: `lib/main.dart`, `lib/app.dart`, `lib/di/locator.dart`
  - done when: app runs to a placeholder home, `GetIt` resolves registered singletons, `GetIt.instance.reset()` works in tests

- [ ] **5. Theme + shared components** — branch `feat/shared-components`
  - touches: `lib/shared/theme/…`, `lib/shared/components/app_error_view.dart`, `empty_state.dart`, `loading_view.dart`, `app_button.dart`, `app_text_field.dart`
  - done when: widget tests pass for each shared component (renders, error retry callback fires, button disabled state)

- [ ] **6. Localization (EN + AR, RTL)** — branch `feat/localization`
  - touches: `l10n.yaml`, `lib/l10n/app_en.arb`, `app_ar.arb`, `lib/app.dart` (locale delegates), locale-switch service in `shared/services/`
  - done when: app renders in EN and AR with correct RTL direction; `flutter gen-l10n` clean; a widget test asserts a translated string

- [ ] **7. Auth feature** — branch `feat/auth`
  - touches: `features/auth/domain/…` (contract, AuthUser, use cases), `features/auth/data/…` (repo impl, data source), `features/auth/presentation/…` (AuthCubit, states, login/signup pages)
  - done when: `bloc_test` covers sign-in/sign-up/sign-out/observe-auth-state incl. error paths; manual smoke: sign up → sign in → sign out against Firebase

- [ ] **8. Routing + auth guard** — branch `feat/routing-auth-guard`
  - touches: `lib/shared/routing/router.dart`, `auth_guard.dart`, wire into `app.dart`
  - done when: unauthenticated → `/login`; authenticated on `/login` → `/home`; deep-link location restored after sign-in; redirect logic unit-tested

- [ ] **9. Doctors feature** — branch `feat/doctors`
  - touches: `features/doctors/domain/…`, `data/…`, `presentation/…` (DoctorsListCubit + search/filter, DoctorProfileCubit, list page, profile page, doctor card, specialty filter bar)
  - done when: `bloc_test` covers load/search/filter/error/empty; manual smoke against seeded Firestore

- [ ] **10. Seed script (Node admin SDK)** — branch `feat/seed-script`
  - touches: `tool/seed/package.json`, `index.js`, `data/…` (sample doctors + images), `firestore.rules` draft, `storage.rules`
  - done when: running `node tool/seed` populates `doctors` + 14 days of `slots` in Firestore and uploads images to Storage; re-run is idempotent (no duplicate doctors)

- [ ] **11. Booking — slot selection** — branch `feat/slot-selection`
  - touches: `features/booking/domain/…` (contract, GetSlots use case), `data/…` (slots read), `presentation/…` (SlotSelectionCubit, day selector, slot tiles, slot selection page)
  - done when: `bloc_test` covers slots-per-day grouping, past-slot filtering, day switching, empty-day state

- [ ] **12. Booking — transaction + confirmation** — branch `feat/booking-transaction`
  - touches: `features/booking/data/booking_repository_impl.dart` (bookSlot transaction), `firestore_booking_data_source.dart`, `presentation/…` (BookingCubit, confirmation page)
  - done when: `fake_cloud_firestore` tests pass for: successful book, **SlotUnavailable abort on concurrent conflict**, slot-not-found; manual smoke: two devices race the same slot

- [ ] **13. Appointments feature** — branch `feat/appointments`
  - touches: `features/appointments/domain/…`, `data/…`, `presentation/…` (AppointmentsCubit, upcoming/past tabs, appointment card, status badge, cancel flow)
  - done when: `bloc_test` covers upcoming/past split, cancel success, cancel-when-already-cancelled error; manual smoke: book → appears in upcoming → cancel → moves to past, slot freed

- [ ] **14. Reschedule** — branch `feat/reschedule`
  - touches: `features/booking/domain/…` (RescheduleAppointment use case), `data/…` (reschedule transaction), `presentation/…` (reschedule mode in slot selection)
  - done when: `fake_cloud_firestore` tests pass for: free-old+book-new atomic, new-slot-taken abort, old-slot-released-on-success; manual smoke: reschedule frees old slot

- [ ] **15. Firestore security rules + indexes** — branch `feat/firestore-rules`
  - touches: `firestore.rules` (Level 1 per plan 2.4), `firestore.indexes.json`, `storage.rules`
  - done when: rules deploy via Firebase CLI; manual smoke: patient can read doctors/slots, book/cancel/reschedule own appointments, cannot write doctors or others' appointments

- [ ] **16. Responsive polish + full verification** — branch `feat/responsive-polish`
  - touches: responsive layout adjustments across pages (LayoutBuilder/MediaQuery per plan), final `flutter analyze` + full `flutter test`
  - done when: `flutter analyze` clean, full test suite green, manual smoke on phone + tablet + desktop/web

---

**Notes**
- Tasks 1–6 are foundation (no Firebase logic yet); 7–8 auth + routing; 9–10 doctors + seed; 11–14 the booking core (the riskiest, each with transaction tests); 15 security hardening; 16 polish.
- The seed script (task 10) is placed *after* doctors (9) so the doctors UI can be built against a schema we control, then seeded for real smoke tests.
- Each task is independently committable; I will not commit or push without your explicit approval, and I'll run the pre-commit safety check (secrets, .env, keystores, local paths) before any commit suggestion.

Approve this task list and I'll start with **Task 1 (project scaffold)**. To begin implementing, please toggle to **Act mode**.