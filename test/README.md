# Test Suite — ClinicGO

Tests are organised by feature and layer (data → domain → view model → view).  
Skipped tests are marked with `[skip]`.

---

## Table of Contents

- [App Shell](#app-shell)
- [Core — Routing](#core--routing)
- [Supabase Config](#supabase-config)
- [Auth](#auth)
- [Calendar](#calendar)
- [Medication](#medication)
- [Home](#home)
- [Profile](#profile)
- [Symptoms](#symptoms)

---

## App Shell

### `main_test.dart`

| Group | Test case | Skip |
|-------|-----------|------|
| ClinicGO | configures the main Material app shell | |
| ClinicGO | renders the home screen search bar | ✓ |
| ClinicGO | deep-links to the dose logging screen with overdue messaging | ✓ |
| ClinicGO | navigates to initial notification route from payload on startup | |
| ClinicGO | shows an error snackbar if dose logging fails | ✓ |
| ClinicGO app shell | renders Home tab by default | |
| ClinicGO app shell | Profile tab shows login form when not logged in | |
| ClinicGO app shell | Profile tab shows "Create account" link | |
| ClinicGO app shell | tapping "Create account" link opens SignUpSheet | |

---

## Core — Routing

### `core/routing/app_router_test.dart`

| Group | Test case |
|-------|-----------|
| AppRouter.onGenerateRoute | returns null for null route name |
| AppRouter.onGenerateRoute | returns null for unknown route |
| AppRouter.onGenerateRoute | returns MaterialPageRoute for /home |
| AppRouter.onGenerateRoute | returns MaterialPageRoute for /login |
| AppRouter.onGenerateRoute | returns MaterialPageRoute for /register |
| AppRouter.onGenerateRoute | returns null for /log-dose/ with no doseId |
| AppRouter.onGenerateRoute | returns null for /log-dose/id missing required params |
| AppRouter.onGenerateRoute | returns null for /log-dose/id with invalid scheduledTime |
| AppRouter.onGenerateRoute | returns MaterialPageRoute for valid /log-dose/ with all params |
| AppRouter.onGenerateRoute | route constants have correct values |

---

## Supabase Config

### `supabase_config_test.dart`

| Group | Test case |
|-------|-----------|
| SupabaseConfig | validate throws StateError when SUPABASE_URL env var is not defined |
| SupabaseConfig | validate error message mentions SUPABASE_URL |

---

## Auth

### `features/auth/data/supabase_auth_service_test.dart`

| Group | Test case |
|-------|-----------|
| currentUserEmail | user logged in → returns email |
| currentUserEmail | no user → returns null |
| isLoggedIn | active session → returns true |
| isLoggedIn | no session → returns false |
| authStateChanges | signedIn event → emits true |
| authStateChanges | signedOut event → emits false |
| signIn | happy path → completes without error |
| signIn | AuthException thrown → propagates |
| signUp | happy path → completes without error |
| signUp | AuthException thrown → propagates |
| signOut | happy path → completes without error |
| signOut | AuthException thrown → propagates |
| resetPassword | happy path → completes without error |
| resetPassword | AuthException thrown → propagates |
| currentUserMetadata | returns user metadata when user is logged in |
| currentUserMetadata | returns empty map when no user |
| updateProfile | happy path → completes without error |
| updateProfile | AuthException with 4xx status → throws validation AuthServiceException |
| updateProfile | AuthException with "network" message → throws network AuthServiceException |
| updateProfile | AuthException with no keyword match → throws unknown AuthServiceException |
| updateProfile | TimeoutException → throws network AuthServiceException |
| updateProfile | generic socket error → throws network AuthServiceException |
| updateProfile | generic unknown error → throws unknown AuthServiceException |

### `features/auth/domain/auth_service_test.dart`

| Group | Test case |
|-------|-----------|
| AuthServiceException | toString includes type and message for validation |
| AuthServiceException | toString includes type and message for network |
| AuthServiceException | toString includes type and message for unknown |
| AuthServiceException | type and message are accessible as fields |

### `features/auth/presentation/view_models/login_view_model_test.dart`

| Group | Test case |
|-------|-----------|
| LoginViewModel | sets errorMessage when email is blank |
| LoginViewModel | sets errorMessage when password is blank |
| LoginViewModel | sets errorMessage when email has no @ |
| LoginViewModel | sets errorMessage to "Invalid credentials" when AuthException is thrown |
| LoginViewModel | sets clearPassword=true on AuthException |
| LoginViewModel | clearPassword resets to false after acknowledgePasswordClear |
| LoginViewModel | sets clearPassword=true on generic error |
| LoginViewModel | clears errorMessage and keeps clearPassword=false on success |
| LoginViewModel | isLoading is false after signIn completes |
| LoginViewModel | sets errorMessage when resetPassword email is blank |
| LoginViewModel | clears errorMessage on successful resetPassword |

### `features/auth/presentation/view_models/sign_up_view_model_test.dart`

| Group | Test case |
|-------|-----------|
| SignUpViewModel | sets errorMessage when email is blank |
| SignUpViewModel | sets errorMessage when password is blank |
| SignUpViewModel | sets errorMessage when email has no @ |
| SignUpViewModel | sets errorMessage when password is shorter than 6 characters |
| SignUpViewModel | sets errorMessage when passwords do not match |
| SignUpViewModel | sets errorMessage to friendly text on AuthException |
| SignUpViewModel | sets errorMessage on generic Exception |
| SignUpViewModel | sets success=true and clears errorMessage on valid sign-up |
| SignUpViewModel | isLoading is false after signUp completes |
| SignUpViewModel | clearError removes the displayed error |

### `features/auth/presentation/views/login_screen_test.dart`

| Group | Test case |
|-------|-----------|
| LoginScreen | renders email and password fields |
| LoginScreen | renders title and sign in button |
| LoginScreen | renders forgot password and create account links |
| LoginScreen | shows error when sign in tapped with empty fields |
| LoginScreen | shows error for invalid email format |
| LoginScreen | shows error on failed sign in |
| LoginScreen | navigates to home after successful sign in |

### `features/auth/presentation/views/register_screen_test.dart`

| Group | Test case |
|-------|-----------|
| RegisterScreen | renders three text fields |
| RegisterScreen | renders title and create account button |
| RegisterScreen | renders already have an account link |
| RegisterScreen | shows error when form is submitted empty |
| RegisterScreen | shows error for invalid email |
| RegisterScreen | shows error when passwords do not match |
| RegisterScreen | shows error when password too short |
| RegisterScreen | navigates back when Sign in link is tapped |

---

## Calendar

### `features/calendar/data/supabase_calendar_repository_test.dart`

| Group | Test case |
|-------|-----------|
| SupabaseCalendarRepository.fetchDoseLogs | throws StateError when no user is authenticated |
| SupabaseCalendarRepository.fetchDoseLogs | returns empty list when there are no logs in range |
| SupabaseCalendarRepository.fetchDoseLogs | returns empty list when logs reference medications not owned by user |
| SupabaseCalendarRepository.fetchDoseLogs | maps a taken log to a DoseLogEntry with correct fields |
| SupabaseCalendarRepository.fetchDoseLogs | maps a skipped log to DoseLogEntry with skipped status |
| SupabaseCalendarRepository.fetchDoseLogs | throws when the medication_logs query fails |

### `features/calendar/presentation/view_models/calendar_view_model_test.dart`

| Group | Test case |
|-------|-----------|
| DaySummary.status | none when both lists are empty |
| DaySummary.status | allTaken when all logs are taken and no scheduled remain |
| DaySummary.status | partial when some logs taken and some skipped |
| DaySummary.status | partial when a taken log exists alongside pending scheduled doses |
| DaySummary.status | missed when no doses taken on a past day |
| DaySummary.status | upcoming when no doses taken on a future day |
| CalendarViewModel.loadMonth | returns 31 summaries for May 2026 |
| CalendarViewModel.loadMonth | clears loading flag and error on success |
| CalendarViewModel.loadMonth | maps a log entry to the correct day summary |
| CalendarViewModel.loadMonth | sets error message when repository throws |
| CalendarViewModel.loadMonth | sets currentMonth to the first day of the requested month |
| CalendarViewModel.loadMonth | transitions isLoading from true to false |
| CalendarViewModel.loadMonth | uses scheduled doses from reminders in day summaries |
| CalendarViewModel navigation | goToNextMonth advances currentMonth to June |
| CalendarViewModel navigation | goToPreviousMonth steps currentMonth back to April |
| CalendarViewModel navigation | goToNextMonth wraps December into January of the following year |
| CalendarViewModel.daySummaryFor | returns null before loadMonth is called |
| CalendarViewModel.daySummaryFor | returns a non-null summary after loadMonth |
| CalendarViewModel.daySummaryFor | returns null for a day outside the loaded month |

### `features/calendar/presentation/views/calendar_screen_test.dart`

| Group | Test case |
|-------|-----------|
| Loading state | shows CircularProgressIndicator while loading |
| Error state | shows error message when repository throws |
| Header and legend | displays the formatted month header |
| Header and legend | displays all four legend labels |
| Day grid | renders the first and last day of May 2026 |
| Day grid | shows check_circle icon on a day with all doses taken |
| Day tap bottom sheet | shows "no activity" message for an empty day |
| Day tap bottom sheet | shows log entry details in the bottom sheet |
| Navigation buttons | chevron_right advances to June 2026 |
| Navigation buttons | chevron_left goes back to April 2026 |

---

## Medication

### `features/medication/data/add_medication_integration_test.dart`

> Hits the real Supabase instance. All tests are skipped unless `--dart-define=SUPABASE_URL=...` credentials are passed.

| Group | Test case | Skip |
|-------|-----------|------|
| addMedication — real Supabase integration | Step 1 — sign-in gives a valid currentUser | ✓* |
| addMedication — real Supabase integration | Step 2 — raw insert into medications table | ✓* |
| addMedication — real Supabase integration | Step 3 — raw insert into medication_reminders table | ✓* |
| addMedication — real Supabase integration | Step 4 — full addMedication via SupabaseMedicationRepository | ✓* |

### `features/medication/data/supabase_dose_log_repository_test.dart`

| Group | Test case |
|-------|-----------|
| insertDoseLog | happy path → inserts without error |
| insertDoseLog | network failure → throws PostgrestException |
| hasDoseLog | log exists → returns true |
| hasDoseLog | no user logged in → returns false immediately |
| hasDoseLog | empty result → returns false |
| hasDoseLog | network failure → throws PostgrestException |

### `features/medication/data/supabase_medication_repository_test.dart`

| Group | Test case |
|-------|-----------|
| addMedication | Happy path: successfully inserts medication and reminders, returns UUID |
| addMedication | Network failure: throws MedicationSaveException when parent insert fails |
| addMedication | Rollback scenario: throws MedicationSaveException and deletes parent if reminders fail |
| fetchMedications | Happy path: successfully returns list of medications |
| fetchMedications | Empty result: returns empty list safely |
| fetchMedications | Network failure: throws PostgrestException |
| fetchMedications | Malformed data: throws on invalid json shape |
| deleteMedication | Happy path: calls delete gracefully |
| deleteMedication | Network failure: passes exception upwards |
| fetchAllReminders | Happy path: successfully returns all reminders |
| fetchAllReminders | Empty result: returns empty list safely |
| fetchAllReminders | Network failure: throws PostgrestException |
| fetchAllReminders | Malformed data: handles invalid structure gracefully |

### `features/medication/models/medication_model_test.dart`

| Group | Test case |
|-------|-----------|
| Medication.fromJson | parses all required fields correctly |
| Medication.fromJson | parses color hex to Flutter Color |
| Medication.fromJson | falls back to default color when color is null |
| Medication.fromJson | accepts null dosage and leaves dosageAmount null |
| Medication.fromJson | defaults dosageUnit to "mg" when dosage_unit is null |
| Medication.fromJson | parses nested medication_reminders list |
| Medication.fromJson | reminders is null when key is absent |
| Medication.fromJson | parses start_date and end_date |
| Medication.dosageDisplay | returns "500mg" when amount=500 and unit="mg" |
| Medication.dosageDisplay | appends unit correctly for different units |
| Medication.dosageDisplay | returns null when dosageAmount is null |
| Medication.isActive | is true when endDate is null (ongoing) |
| Medication.isActive | is true when endDate is in the future |
| Medication.isActive | is false when endDate is in the past |
| Medication.colorFromHex / colorToHex | colorFromHex parses #RRGGBB correctly |
| Medication.colorFromHex / colorToHex | colorToHex formats Color to #RRGGBB |
| Medication.colorFromHex / colorToHex | colorFromHex and colorToHex round-trip |
| MedicationReminder.fromJson | parses all fields |
| MedicationReminder.fromJson | defaults isActive to true when absent |
| MedicationReminder.fromJson | toInsertJson produces expected keys |
| ScheduledDose serialisation | toJson produces expected map |
| ScheduledDose serialisation | fromJson round-trips toJson |

### `features/medication/presentation/view_models/add_medication_view_model_test.dart`

| Group | Test case |
|-------|-----------|
| Validation | submit with empty name sets nameError |
| Validation | submit with empty dosage sets dosageError |
| Validation | submit with both blank fields sets both errors |
| Validation | setName clears nameError |
| Happy path | sets isSuccess after successful submit |
| Happy path | isDirty becomes false after successful submit |
| Happy path | payload contains selected colour |
| Rollback path | sets errorMessage when MedicationSaveException is thrown |
| Rollback path | sets generic errorMessage on unknown exception |
| Colour picker | setColor updates selectedColor |
| Colour picker | setColor marks form as dirty |
| Reminder slots | Twice daily produces two reminder slots |
| Reminder slots | Three times daily produces three slots |
| Reminder slots | switching back to Once daily reduces to one slot |

### `features/medication/presentation/view_models/daily_doses_view_model_test.dart`

| Group | Test case |
|-------|-----------|
| DailyDosesViewModel – initial state | starts empty, not loading, no error |
| DailyDosesViewModel – loadTodayDoses | toggles isLoading true then false |
| DailyDosesViewModel – loadTodayDoses | loads pending doses not yet logged |
| DailyDosesViewModel – loadTodayDoses | excludes doses already logged |
| DailyDosesViewModel – loadTodayDoses | sets errorMessage and leaves doses empty on repo failure |
| DailyDosesViewModel – loadTodayDoses | refresh calls loadTodayDoses |
| DailyDosesViewModel – loadTodayDoses | doses list is unmodifiable |
| DailyDosesViewModel – logDose | throws StateError when dose is not in the loaded list |
| DailyDosesViewModel – logDose | marks dose as taken after successful log |
| DailyDosesViewModel – logDose | marks dose as skipped after successful log |
| DailyDosesViewModel – logDose | rollback on log repository failure restores prior state |
| DailyDosesViewModel – logDose | delegates to notificationController when provided |
| DailyDosesViewModel – dose disappears after refresh | taken dose is absent after refresh |
| DailyDosesViewModel – dose disappears after refresh | skipped dose is absent after refresh |
| DailyDosesViewModel – dose disappears after refresh | only logged dose is removed, other doses remain after refresh |
| DailyDosesViewModel – dose disappears after refresh | taken dose via notification controller is absent after refresh when controller shares the log repository |

### `features/medication/presentation/view_models/edit_medication_view_model_test.dart`

| Group | Test case |
|-------|-----------|
| EditMedicationViewModel – initial state | pre-fills all fields from the medication object |
| EditMedicationViewModel – loadReminders | populates slots from repository |
| EditMedicationViewModel – loadReminders | falls back to single 08:00 slot when repository returns empty |
| EditMedicationViewModel – loadReminders | falls back to single slot when repository throws |
| EditMedicationViewModel – validation | submit with blank name sets nameError and returns early |
| EditMedicationViewModel – validation | submit with null dosage sets dosageError and returns early |
| EditMedicationViewModel – validation | submit with both blank sets both errors |
| EditMedicationViewModel – happy path submit | sets isSuccess and clears isDirty after successful save |
| EditMedicationViewModel – submit failure | sets errorMessage when repo throws, isSuccess stays false |
| EditMedicationViewModel – deleteMedication | sets wasDeleted and isSuccess on success |
| EditMedicationViewModel – deleteMedication | sets errorMessage and keeps wasDeleted false on failure |

### `features/medication/presentation/view_models/medications_list_view_model_test.dart`

| Group | Test case |
|-------|-----------|
| MedicationsListViewModel – initial state | starts with empty list, not loading, no error |
| MedicationsListViewModel – loadMedications | sets isLoading to true during fetch then false after |
| MedicationsListViewModel – loadMedications | populates medications list on success |
| MedicationsListViewModel – loadMedications | returns empty list when repository returns no medications |
| MedicationsListViewModel – loadMedications | sets errorMessage and leaves list empty on repository error |
| MedicationsListViewModel – loadMedications | clears previous errorMessage on successful retry |
| MedicationsListViewModel – loadMedications | medications list is unmodifiable |

### `features/medication/presentation/views/add_medication_screen_test.dart`

| Test case |
|-----------|
| renders all required form fields and colour swatch |
| tapping Save with empty fields shows validation errors |
| Save button shows spinner while loading |
| tapping colour swatch opens colour picker bottom sheet |
| error message is shown when repository throws |

### `features/medication/presentation/views/dose_logging_screen_test.dart`

| Group | Test case |
|-------|-----------|
| DoseLoggingScreen – rendering | renders medication name, dosage and action buttons |
| DoseLoggingScreen – rendering | shows overdue banner when isOverdue is true |
| DoseLoggingScreen – rendering | does not show overdue banner when isOverdue is false |
| DoseLoggingScreen – mark as taken | shows success state and snackbar after marking taken |
| DoseLoggingScreen – skip dose | shows success state and snackbar after skipping |
| DoseLoggingScreen – error handling | log failure shows error snackbar and rolls back buttons |

### `features/medication/presentation/views/edit_medication_screen_test.dart`

| Group | Test case |
|-------|-----------|
| EditMedicationScreen – rendering | shows title and pre-filled name and dosage |
| EditMedicationScreen – rendering | shows Guardar alterações and Cancelar buttons |
| EditMedicationScreen – rendering | shows colour swatch |
| EditMedicationScreen – validation | Save with blank name shows name error |
| EditMedicationScreen – success | successful save shows snackbar and pops screen |
| EditMedicationScreen – error | repo error shows error message in form |

### `features/medication/presentation/views/medications_list_screen_test.dart`

| Test case |
|-----------|
| shows empty state when no medications |
| renders medication cards with correct background colours |
| tapping info+ expands a card to show details |
| tapping info- collapses the expanded card |
| shows error state and Retry button on fetch failure |

### `features/medication/services/dose_scheduling_service_test.dart`

| Group | Test case |
|-------|-----------|
| calculateUpcomingDoses | Happy path → returns correctly scheduled doses |
| calculateUpcomingDoses | Lookback → finds overdue doses in the past |
| calculateUpcomingDoses | Empty result → returns empty list if no reminders |
| calculateUpcomingDoses | Boundaries → respects duration limit exactly |

### `features/medication/services/local_notification_gateway_test.dart`

| Group | Test case |
|-------|-----------|
| NoopLocalNotificationGateway | schedule completes without error |
| NoopLocalNotificationGateway | cancel completes without error |
| NoopLocalNotificationGateway | cancel with any id completes |
| NotificationRequest | stores all fields correctly |

### `features/medication/services/missed_dose_notification_controller_test.dart`

| Group | Test case |
|-------|-----------|
| MissedDoseNotificationController | schedules primary and missed notifications with deterministic IDs |
| MissedDoseNotificationController | cancels the pending missed notification after logging a dose |
| MissedDoseNotificationController | keeps the pending missed notification when the dose log insert fails |
| MissedDoseNotificationController | startup sync cancels locally pending missed notifications logged on another device |
| MissedDoseNotificationController | sync skips notifications whose dose has not been logged yet |
| MissedDoseNotificationController | cancelMissedDoseNotification cancels the correct notification ID |
| MissedDoseNotificationController | buildDoseLoggingRoute contains scheduled status when not overdue |
| MissedDoseNotificationController | buildDoseLoggingRoute contains overdue status when overdue |
| MissedDoseNotificationController | primaryNotificationIdForDose differs from missedNotificationIdForDose |
| MissedDoseNotificationController | logDose with explicit loggedAt uses that timestamp |

### `features/medication/services/pending_notification_store_test.dart`

| Group | Test case |
|-------|-----------|
| loadPending | empty prefs → returns empty list |
| loadPending | prefs contain one notification → returns it with correct fields |
| loadPending | malformed JSON in prefs → throws |
| upsert | new notification on empty store → loadPending returns 1 item |
| upsert | same doseId → replaces existing entry, count stays at 1 |
| upsert | different doseId → both entries coexist |
| removeByDoseId | existing doseId → removed, loadPending returns empty |
| removeByDoseId | non-existent doseId → no error, other items remain |

---

## Home

### `features/home/presentation/view_models/home_view_model_test.dart`

| Group | Test case |
|-------|-----------|
| HomeViewModel – loadNextDose | Loading state → sets isLoading correctly during fetch |
| HomeViewModel – loadNextDose | Success state → identifies the next upcoming dose |
| HomeViewModel – loadNextDose | Overdue state → identifies an overdue dose |
| HomeViewModel – loadNextDose | Empty result → handles case with no medications safely |
| HomeViewModel – loadNextDose | Empty result → ignores doses already logged |

### `features/home/presentation/views/main_screen_widget_test.dart`

| Group | Test case | Skip |
|-------|-----------|------|
| HomeContent Widget Tests | Loading state → spinner is visible | |
| HomeContent Widget Tests | Empty state → "No upcoming doses" message is visible | ✓ |
| HomeContent Widget Tests | Success state (Upcoming) → dose card is rendered correctly | ✓ |
| HomeContent Widget Tests | Success state (Overdue) → warning icon and red text are visible | ✓ |
| HomeContent Widget Tests | User interactions → tapping Log Dose triggers navigation | ✓ |

---

## Profile

### `features/profile/presentation/view_models/profile_view_model_test.dart`

| Group | Test case |
|-------|-----------|
| ProfileViewModel | safely ignores non-string metadata values |
| ProfileViewModel | shows network-specific message when profile update fails offline |
| ProfileViewModel | shows validation-specific message for rejected profile data |
| ProfileViewModel | shows generic message for unknown profile update failure |
| ProfileViewModel | sets errorMessage when name is empty |
| ProfileViewModel | sets errorMessage when email is empty |
| ProfileViewModel | sets errorMessage when email has no @ |
| ProfileViewModel | sets infoMessage on successful update |
| ProfileViewModel | sets errorMessage on non-AuthServiceException update error |
| signIn | sets infoMessage on success |
| signIn | sets errorMessage when email is empty |
| signIn | sets errorMessage when password is empty |
| signIn | sets errorMessage when email has no @ |
| signIn | sets errorMessage on sign in failure |
| resetPassword | sets infoMessage on success |
| resetPassword | sets errorMessage when email is empty |
| resetPassword | sets errorMessage on failure |
| signOut | sets infoMessage on success |
| signOut | sets errorMessage on failure |
| displayName | returns name when set |
| displayName | falls back to full_name when name is empty |
| displayName | returns empty string when both name and full_name are absent |
| clearMessages and refreshSession | clearMessages removes both error and info messages |
| clearMessages and refreshSession | refreshSession notifies listeners without throwing |

### `features/profile/presentation/views/profile_view_test.dart`

| Group | Test case |
|-------|-----------|
| ProfileView — logged out | renders email and password fields |
| ProfileView — logged out | renders "Continue with" divider |
| ProfileView — logged out | renders Forgot password and Create one now links |
| ProfileView — logged out | renders Continue button |
| ProfileView — logged out | shows error when Continue tapped with empty fields |
| ProfileView — logged out | shows error for invalid email format |
| ProfileView — logged out | shows error on failed sign in |
| ProfileView — logged out | shows error when Forgot password tapped with empty email |
| ProfileView — logged out | shows success info when Forgot password tapped with valid email |
| ProfileView — logged in | renders user name uppercased |
| ProfileView — logged in | renders Edit and Logout buttons |
| ProfileView — logged in | renders profile field labels in view mode |
| ProfileView — logged in | shows email value in profile view |
| ProfileView — logged in | tapping Edit switches to edit mode with Save and Cancel |
| ProfileView — logged in | tapping Cancel reverts to view mode |
| ProfileView — logged in | edit mode shows text fields for profile fields |
| ProfileView — logged in | successful logout shows info message |
| ProfileView — logged in | failed logout shows error message |
| ProfileView — logged in | user with no name falls back to USER_TEST |
| ProfileView — logged in | successful profile save exits edit mode |
| ProfileView — logged in | failed profile save shows error message |

---

## Symptoms

### `features/symptoms/data/symptom_repository_test.dart`

| Group | Test case |
|-------|-----------|
| insertSymptomLog | Happy path: calls insert without throwing |
| insertSymptomLog | Empty notes string is saved as null |
| insertSymptomLog | Network failure: rethrows PostgrestException |
| fetchSymptomLogs | Returns empty list when no user is signed in |
| fetchSymptomLogs | Happy path: parses and returns log list |
| fetchSymptomLogs | Returns empty list when database returns no rows |
| fetchSymptomLogs | Network failure: throws PostgrestException |
| fetchSymptomLogs | Malformed row: throws when required field is missing |

### `features/symptoms/models/symptom_log_test.dart`

| Group | Test case |
|-------|-----------|
| SymptomLog.fromJson | parses all fields correctly |
| SymptomLog.fromJson | accepts null notes |
| SymptomLog.fromJson | uses custom_symptom when there is no linked symptom |
| SymptomLog.fromJson | throws TypeError when required field id is missing |
| SymptomLog.fromJson | throws when occurred_at is not a valid date string |
| SymptomLog.fromJson | throws when severity is not an int |
| SymptomLog.symptomLabel | single word: capitalises first letter |
| SymptomLog.symptomLabel | two-segment type converts to title case with space |
| SymptomLog.symptomLabel | three-segment type converts all segments |
| SymptomLog.symptomLabel | muscle_pain converts to Muscle Pain |

### `features/symptoms/presentation/view_models/symptom_form_controller_test.dart`

| Group | Test case |
|-------|-----------|
| Initial state | starts with severity 3, no symptom, not dirty, not loading |
| selectSymptom | sets selectedSymptom and marks form dirty |
| selectSymptom | clears errorMessage when a symptom is selected |
| selectSymptom | can switch selection from one symptom to another |
| setSeverity | rounds float value to nearest int |
| setSeverity | clamps below 1 to 1 |
| setSeverity | clamps above 10 to 10 |
| setSeverity | marks form dirty |
| Text setters | setNotes updates notes and marks dirty |
| Text setters | setSearchQuery updates searchQuery without marking dirty |
| Text setters | setOccurredAt updates occurredAt and marks dirty |
| filteredSymptoms | returns all 14 symptoms when query is empty |
| filteredSymptoms | filters by partial match on headache |
| filteredSymptoms | filters across underscore-separated words |
| filteredSymptoms | returns empty list when query matches nothing |
| submitSymptomLog | returns false and sets error when user is not signed in |
| submitSymptomLog | returns false and sets error when no symptom is selected |
| submitSymptomLog | Happy path: returns true and resets state |
| submitSymptomLog | Failure path: returns false and sets connection error message |

### `features/symptoms/presentation/views/log_symptom_screen_test.dart`

| Group | Test case |
|-------|-----------|
| Rendering | shows all section headings |
| Rendering | shows symptom chips including Headache and Nausea |
| Rendering | shows search field and Save button |
| Symptom search | typing in search filters the chip list |
| Symptom search | clearing search restores all chips |
| Validation | tapping Save with no symptom selected shows error banner |
| Validation | tapping Save when not signed in shows sign-in error |
| Loading state | shows spinner while save is in progress |
| Successful save | pops screen and shows snackbar on success |

### `features/symptoms/presentation/views/symptom_history_screen_test.dart`

| Group | Test case |
|-------|-----------|
| Loading state | shows CircularProgressIndicator while loading |
| Empty state | shows empty-state message when log list is empty |
| Data state | renders a card for each symptom log |
| Data state | shows severity badge for each log |
| Data state | shows notes when present |
| Data state | does not show notes section when notes is null |
| Error state | shows error message when provider fails |
