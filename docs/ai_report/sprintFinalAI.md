# AI Usage Report — Final Sprint
**Project:** ClinicGO · **Repo:** LEIC-ES-2025-26-2LEIC07/T2
**Period:** 2026-05-16 → 2026-06-06
**Author:** David

---

## 1. Tool Used

| Field | Value |
|---|---|
| **Tool** | Claude Code (Anthropic) |
| **Model** | Claude Sonnet 4.6 (`claude-sonnet-4-6`) |
| **Interface** | Claude Code CLI + VSCode Extension |
| **Convention** | All AI-generated commits are prefixed `[MISTER AI]` |

---

## 2. AI-Generated Commits

All commits below were produced autonomously by the AI and committed independently from human-authored commits.

| Date | Commit | Description |
|---|---|---|
| 2026-05-17 | `1009f03` | style: dart format |
| 2026-05-17 | `1040386` | refactor: extract widgets from edit_medication and medications_list screens |
| 2026-05-17 | `bc8c264` | refactor: extract widgets from log_symptom and monthly_summary screens |
| 2026-05-17 | `0e6f6ca` | refactor: extract widgets from profile_view into profile_widgets |
| 2026-05-17 | `ec1abe6` | refactor: split main_screen and fix integration test skip |
| 2026-05-17 | `4c2c393` | feat: redesign edit_medication_screen to match Clinical Blue mockup |
| 2026-05-17 | `341dfb7` | refactor: extract shared form widgets from add/edit medication screens |
| 2026-05-17 | `7472807` | test: add missing ViewModel and model unit tests |
| 2026-05-17 | `56e5c20` | feat: split dosage into int amount + unit selector |
| 2026-05-18 | `e1d3e6a` | refactor: replace hardcoded colors with AppColors palette across 18 files |
| 2026-05-18 | `0b1224e` | feat: update Android launcher icon with ClinicGO brand assets |
| 2026-05-18 | `5337928` | test: add missing widget tests for low/medium priority user scenarios |
| 2026-05-18 | `f253d87` | fix: correct dose ID parsing in CalendarViewModel and scope home next-dose to today |
| 2026-05-18 | `e087a76` | test: add high-priority tests for EditMedicationViewModel and EditMedicationScreen |
| 2026-05-19 | `945660c` | test(integration): add UAT acceptance tests for US02, US04 and US07 journeys |
| 2026-05-20 | `44d3475` | fix: P0 calendar deduplication, 9 failing tests, CI secrets + cache |
| 2026-05-21 | `0be0bdd` | feat: add splash screen with wallpaper-sky background |
| 2026-05-21 | `70ed177` | fix(tests): update auth and app-shell tests for English UI and SplashScreen home |
| 2026-05-21 | `ce4ebfe` | feat: restore Portuguese auth UI and fix all test suite failures |
| 2026-05-21 | `23e6436` | feat: translate navbar labels to Portuguese |
| 2026-05-21 | `226ed32` | refactor: split home_widgets.dart into focused widget files |
| 2026-05-21 | `2d7298b` | fix: integration tests, add 3 new journeys, refactor hardcoded colors |
| 2026-05-21 | `b574838` | fix: resolve rebase conflicts and post-rebase issues |
| 2026-05-22 | `86e772a` | fix: address all 6 review issues before merge (emergency alerts PR) |
| 2026-05-22 | `c462d07` | fix: address PR review issues in emergency alerts feature |
| 2026-05-22 | `8651760` | fix: commit firebase_options.dart and remove from gitignore |
| 2026-05-22 | `4586cc7` | fix: make emergency alerts migration idempotent |
| 2026-05-22 | `56d85d9` | fix: remove duplicate migration causing schema_migrations conflict |
| 2026-05-22 | `2fd284f` | ci: opt into Node.js 24 for GitHub Actions |
| 2026-05-22 | `0faf625` | feat: update symptom logging screen and translations |
| 2026-05-22 | `c1bc371` | fix: cancel local notification when acknowledging emergency alert |
| 2026-05-22 | `898a4c4` | fix: skip missed dose notifications for previous days and past grace periods |
| 2026-05-22 | `23b7b80` | fix: rename frequency migration to avoid duplicate schema_migrations version |
| 2026-05-22 | `6d18c23` | chore: remove frequency migration (applied manually to production) |
| 2026-05-22 | `c5a6ff2` | refactor: strip settings branch to visual-only shell |
| 2026-05-22 | `381114c` | fix: migrate app to Flutter built-in Kotlin Gradle Plugin |
| 2026-05-22 | `ebb1db5` | fix: offset floating navbar above Android system navigation bar |
| 2026-05-22 | `f9dc6c9` | feat: redesign CalendarScreen with neo-brutalist style and doses panel |
| 2026-05-22 | `09a5c66` | fix: re-add kotlinOptions to align JVM target with Java 17 |
| 2026-05-22 | `26ceba3` | fix: correct login screen test assertion to BEM-VINDO DE VOLTA |
| 2026-05-22 | `4b96a4d` | fix: calendar day updates in real-time and respects medication creation date |
| 2026-05-23 | `b3c5991` | chore: add mockup images to docs/img and fix CodeQL workflow |
| 2026-06-06 | `d8bdbf0` | feat: migrate medication reminders from local scheduling to Supabase FCM |
| 2026-06-06 | `5b9bb82` | fix: use consistent notification ID so tapping a reminder dismisses it |

---

## 3. Prompts Used

Prompts were entered conversationally via the Claude Code CLI interface. The following table documents each interaction session with the representative prompt that triggered the AI-generated work.

### 3.1 UI Redesign & Visual Polish

| PBI | Prompt | Outcome |
|---|---|---|
| — | *"Redesign the edit medication screen to match the Clinical Blue mockup. Extract shared form widgets from add and edit screens."* | `4c2c393`, `341dfb7` — edit screen redesign + shared widgets |
| — | *"Split dosage into separate int amount and unit selector (mg, ml, etc.)"* | `56e5c20` — dosage field split |
| — | *"Replace all hardcoded color hex values with AppColors tokens across the whole codebase."* | `e1d3e6a` — 18 files cleaned |
| — | *"Add a splash screen using the wallpaper-sky background and ClinicGO logo."* | `0be0bdd` — splash screen |
| — | *"Restore the Portuguese auth UI. The login and register screens reverted to English."* | `ce4ebfe` — PT auth UI restored |
| — | *"Translate the navbar labels to Portuguese: PERFIL · MEDS · INÍCIO · PLANO · CONFIG."* | `23e6436` — navbar PT labels |
| — | *"Redesign the CalendarScreen with the neo-brutalist style and add a doses panel."* | `f9dc6c9` — calendar neo-brutalist |
| — | *"Update the symptom logging screen with improved translations and UX."* | `0faf625` — symptom screen |
| — | *"Update the Android launcher icon with the ClinicGO brand assets."* | `0b1224e` — app icon |

### 3.2 Refactoring & Architecture

| PBI | Prompt | Outcome |
|---|---|---|
| — | *"Extract widgets from edit_medication and medications_list into separate files."* | `1040386` — widget extraction |
| — | *"Extract widgets from log_symptom and monthly_summary screens."* | `bc8c264` — widget extraction |
| — | *"Extract widgets from profile_view into profile_widgets."* | `0e6f6ca` — widget extraction |
| — | *"Split main_screen.dart — it's too large."* | `ec1abe6` — main_screen split |
| — | *"Split home_widgets.dart into focused widget files."* | `226ed32` — home widgets split |

### 3.3 Bug Fixes

| PBI | Prompt | Outcome |
|---|---|---|
| — | *"Fix the dose ID parsing in CalendarViewModel. Doses are being shown for the wrong day."* | `f253d87` — calendar dose ID fix |
| — | *"Calendar deduplication is broken — P0 bug."* | `44d3475` — dedup + 9 tests + CI cache |
| — | *"Fix the floating navbar — it's hidden behind the Android system navigation bar."* | `ebb1db5` — navbar offset fix |
| — | *"The app crashes on build — Kotlin Gradle Plugin version mismatch."* | `381114c`, `09a5c66` — Kotlin fixes |
| — | *"Calendar day doesn't update in real time after adding a medication."* | `4b96a4d` — real-time calendar fix |
| — | *"When I acknowledge an emergency alert, the local notification doesn't get cancelled."* | `c1bc371` — notification cancel fix |
| — | *"Missed dose notifications are firing for previous days."* | `898a4c4` — past-day guard |
| — | *"Quando carrego na notificação aquilo não sai."* | `5b9bb82` — notification dismiss fix (ID mismatch) |

### 3.4 Emergency Alerts Feature (Firebase FCM)

| PBI | Prompt | Outcome |
|---|---|---|
| #122 | *"Implement emergency alerts with Firebase push notifications. Server sends FCM when a critical event occurs, app displays a banner."* | `86e772a`, `c462d07`, `8651760`, `4586cc7`, `56d85d9`, `b574838` — full FCM feature + PR review fixes |

### 3.5 Notification Architecture Migration

| PBI | Prompt (paraphrased) | Outcome |
|---|---|---|
| #135 | *"Nao posso meter o supabase a tratar disso? Local notifications aren't firing on device. Move the responsibility to Supabase."* | `d8bdbf0` — server-side migration |

The AI diagnosed that `flutter_local_notifications` was unreliable on Android due to `SCHEDULE_EXACT_ALARM` permission restrictions, missing notification channels, and OS-level process killing (particularly on Xiaomi/MIUI). The proposed and implemented solution was:

1. **Supabase Edge Function** `send-medication-reminders` — queries `medication_reminders` WHERE `reminder_time` matches the current Lisbon-timezone minute, joins with `device_push_tokens`, and sends FCM via the v1 API using a Google service account JWT.
2. **pg_cron job** — triggers the Edge Function every minute.
3. **`EmergencyAlertController`** extended to handle `type: medication_reminder` FCM messages — shows a local notification in foreground, navigates to dose logging on tap.

### 3.6 Tests

| PBI | Prompt | Outcome |
|---|---|---|
| — | *"Add missing ViewModel and model unit tests."* | `7472807` — ViewModel/model tests |
| — | *"Add missing widget tests for low/medium priority user scenarios."* | `5337928` — widget tests |
| — | *"Add high-priority tests for EditMedicationViewModel and EditMedicationScreen."* | `e087a76` — edit medication tests |
| — | *"Add UAT acceptance tests for US02, US04 and US07 journeys."* | `945660c` — 3 integration test journeys |
| — | *"Fix integration tests, add 3 new journeys."* | `2d7298b` — integration test fixes |

### 3.7 CI/CD

| PBI | Prompt | Outcome |
|---|---|---|
| — | *"Opt into Node.js 24 for GitHub Actions — deprecation warning."* | `2fd284f` — Node 24 upgrade |
| — | *"Fix the CodeQL workflow — it's failing."* | `b3c5991` — CodeQL fix |

---

## 4. PBIs to Label as "MisterAI"

| Issue | Title |
|---|---|
| #122 | Emergency alerts push notifications |
| #135 | bug: local medication reminder notifications not displayed on device |

> All other work in this sprint was performed on non-issue branches (refactors, UI polish, CI fixes). These are tracked solely by the `[MISTER AI]` commit prefix.

---

## 5. Key Architectural Decision — Server-Side Notification Delivery

The most significant AI contribution of the final sprint was diagnosing and solving the notification delivery failure at the infrastructure level.

**Problem:** `flutter_local_notifications` scheduled exact alarms that never fired on real Android devices due to `SCHEDULE_EXACT_ALARM` permission restrictions (Android 12+), OEM battery optimization (Xiaomi/MIUI killing background processes), and missing notification channels causing silent drops.

**Solution implemented by AI:**

```
pg_cron (every minute)
  → Supabase Edge Function "send-medication-reminders"
      → SELECT medication_reminders WHERE time == NOW() (Lisbon TZ)
      → JOIN device_push_tokens
      → POST FCM v1 API → device
          → EmergencyAlertController handles "medication_reminder" type
              → foreground: show local notification via LocalNotificationGateway
              → tap: navigate to /log-dose/{doseId}
```

This eliminates all client-side scheduling, works when the app is closed, and removes the dependency on Android exact alarm permissions entirely.

---

## 6. Interaction Model

All prompts were entered as natural language in the Claude Code CLI terminal inside VSCode. The AI:

1. **Read** the relevant source files and wiki pages before making changes.
2. **Proposed** a plan when the task was non-trivial (architecture decisions, new features).
3. **Implemented** changes directly in the repo files using Edit/Write tools.
4. **Ran** `flutter analyze --no-pub` and `dart format .` to verify correctness before reporting done.
5. **Committed** the resulting changes in isolated commits with the `[MISTER AI]` prefix.
6. **Deployed** the Supabase Edge Function and configured pg_cron directly from the CLI.

Human review was performed after each AI session before merging to `main`.
