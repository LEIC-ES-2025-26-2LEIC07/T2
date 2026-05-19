# Project Testing Overview

High-level summary of test coverage by feature and layer. For the complete test-by-test table, see [README.md](README.md).

Run the full suite with `flutter test`.

---

## 1. Core Architecture & Infrastructure

- **App bootstrapping & routing** — `main_test.dart`, `core/routing/app_router_test.dart`
  - Material app shell setup, bottom-tab navigation, deep-link routing for dose logging, notification payload handling on startup
- **Supabase configuration** — `supabase_config_test.dart`
  - Environment variable validation and error messages

---

## 2. Authentication

- **Supabase auth service** — `features/auth/data/supabase_auth_service_test.dart`
  - Sign-in, sign-up, sign-out, password reset, session state, auth state stream, profile updates with typed exception mapping
- **Auth domain model** — `features/auth/domain/auth_service_test.dart`
  - `AuthServiceException` fields and string representation
- **Login ViewModel** — `features/auth/presentation/view_models/login_view_model_test.dart`
  - Input validation, auth error states, loading flag, password-clear handshake after failure
- **Sign-up ViewModel** — `features/auth/presentation/view_models/sign_up_view_model_test.dart`
  - Field validation, password confirmation, error/success states, loading flag
- **Login screen (widget)** — `features/auth/presentation/views/login_screen_test.dart`
  - UI rendering, validation feedback, successful navigation to home
- **Register screen (widget)** — `features/auth/presentation/views/register_screen_test.dart`
  - Field rendering, validation errors, navigation back to login

---

## 3. Calendar

- **Supabase calendar repository** — `features/calendar/data/supabase_calendar_repository_test.dart`
  - Dose log fetch with auth guard, date-range filtering, JSON mapping for taken/skipped logs, error propagation
- **Calendar ViewModel** — `features/calendar/presentation/view_models/calendar_view_model_test.dart`
  - Month loading, day summary status logic (none/allTaken/partial/missed/upcoming), month navigation with year wrap
- **Calendar screen (widget)** — `features/calendar/presentation/views/calendar_screen_test.dart`
  - Loading/error states, day grid rendering, legend, bottom-sheet on day tap, chevron navigation

---

## 4. Medication

- **Supabase medication repository** — `features/medication/data/supabase_medication_repository_test.dart`
  - Add (with rollback on partial failure), fetch, delete, fetch reminders
- **Supabase dose log repository** — `features/medication/data/supabase_dose_log_repository_test.dart`
  - Insert and existence check with auth guard and network failure paths
- **Integration test** *(real Supabase DB)* — `features/medication/data/add_medication_integration_test.dart`
  - Four-step ladder: auth → raw medication insert → raw reminder insert → full repository path. Skipped unless `--dart-define` credentials are provided.
- **Medication model** — `features/medication/models/medication_model_test.dart`
  - `Medication.fromJson` field parsing, colour hex conversion, `dosageDisplay`, `isActive`, `MedicationReminder.fromJson`, `ScheduledDose` JSON round-trip
- **Add medication ViewModel** — `features/medication/presentation/view_models/add_medication_view_model_test.dart`
  - Validation, success/rollback paths, colour picker, reminder slot count per frequency
- **Daily doses ViewModel** — `features/medication/presentation/view_models/daily_doses_view_model_test.dart`
  - Today's dose list, logged-dose exclusion, log/skip/rollback, notification controller delegation, refresh removes logged doses
- **Edit medication ViewModel** — `features/medication/presentation/view_models/edit_medication_view_model_test.dart`
  - Pre-fill from model, reminder loading with fallback, validation, save and delete paths
- **Medications list ViewModel** — `features/medication/presentation/view_models/medications_list_view_model_test.dart`
  - Fetch, loading state toggle, empty/error states, immutable list
- **Add medication screen (widget)** — `features/medication/presentation/views/add_medication_screen_test.dart`
  - Form rendering, validation errors, loading spinner, colour picker sheet, error banner
- **Dose logging screen (widget)** — `features/medication/presentation/views/dose_logging_screen_test.dart`
  - Rendering, overdue banner, mark-as-taken flow, skip flow, error with button rollback
- **Edit medication screen (widget)** — `features/medication/presentation/views/edit_medication_screen_test.dart`
  - Pre-filled form, validation, successful save with snackbar and pop, error display
- **Medications list screen (widget)** — `features/medication/presentation/views/medications_list_screen_test.dart`
  - Empty state, card rendering with colours, expand/collapse card, error state with retry
- **Dose scheduling service** — `features/medication/services/dose_scheduling_service_test.dart`
  - Upcoming and overdue dose calculation, empty-reminder result, boundary conditions
- **Local notification gateway** — `features/medication/services/local_notification_gateway_test.dart`
  - Noop implementation contracts, `NotificationRequest` model field storage
- **Missed dose notification controller** — `features/medication/services/missed_dose_notification_controller_test.dart`
  - Primary + missed notification scheduling, cancellation on log, startup sync, route building, deterministic ID uniqueness
- **Pending notification store** — `features/medication/services/pending_notification_store_test.dart`
  - SharedPreferences persistence, upsert deduplication by doseId, remove by doseId

---

## 5. Home

- **Home ViewModel** — `features/home/presentation/view_models/home_view_model_test.dart`
  - Next-dose identification, overdue detection, empty/already-logged cases
- **Main screen (widget)** — `features/home/presentation/views/main_screen_widget_test.dart`
  - Loading, empty, upcoming, overdue states; Log Dose navigation

---

## 6. Profile

- **Profile ViewModel** — `features/profile/presentation/view_models/profile_view_model_test.dart`
  - Sign-in/out, password reset, profile update with typed error messages, display name fallback chain, message clearing
- **Profile screen (widget)** — `features/profile/presentation/views/profile_view_test.dart`
  - Logged-out UI (auth forms, forgot password, create account link), logged-in UI (view/edit mode toggle, logout, profile save)

---

## 7. Symptoms

- **Symptom repository** — `features/symptoms/data/symptom_repository_test.dart`
  - Insert (empty-notes coercion to null), fetch (auth guard, JSON parsing, empty result, network error)
- **SymptomLog model** — `features/symptoms/models/symptom_log_test.dart`
  - JSON parsing, null notes, `symptomLabel` underscore-to-title-case conversion
- **Symptom form controller** — `features/symptoms/presentation/view_models/symptom_form_controller_test.dart`
  - Symptom selection, severity clamping and rounding, text setters, search filtering, submit paths (auth guard, missing selection, success, failure)
- **Log symptom screen (widget)** — `features/symptoms/presentation/views/log_symptom_screen_test.dart`
  - Section rendering, chip list, search filter and clear, validation banners, loading state, success with snackbar and pop
- **Symptom history screen (widget)** — `features/symptoms/presentation/views/symptom_history_screen_test.dart`
  - Loading, empty, data cards (severity badge, conditional notes), error state
