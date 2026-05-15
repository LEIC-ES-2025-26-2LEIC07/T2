# AI Usage Report — Sprint 3
**Project:** ClinicGO · **Repo:** LEIC-ES-2025-26-2LEIC07/T2
**Period:** 2026-04-22 → 2026-05-15
**Author:** David (df668203@gmail.com)

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
| 2026-04-22 | `acee0da` | refactor: restructure architecture — domain models and services to repository patterns |
| 2026-04-22 | `f1e6ebb` | feat: add reminderId to scheduled doses and update Android manifest for exact alarms |
| 2026-04-23 | `e60dd57` | feat: implement "Today's Doses" section in MedicationsListScreen and update dose logging schema |
| 2026-04-23 | `e39fdd9` | refactor: update overdue dose button text and remove unused code |
| 2026-04-26 | `7f5c985` | refactor: rename package and update medication repository to return saved IDs for notification scheduling |
| 2026-04-28 | `371b80d` | refactor: improve main menu and home screen legibility |
| 2026-05-01 | `13d4797` | fix: correct test mocks for medication repository |
| 2026-05-12 | `ca3eeda` | test: add unit and widget tests for calendar feature |
| 2026-05-13 | `7389682` | test: increase unit and widget test coverage across auth, profile and routing |
| 2026-05-13 | `2b5bded` | test: add coverage for profile view, app startup routing, and supabase config |
| 2026-05-13 | `781c0b4` | test: skip home screen tests that depend on removed UI elements |
| 2026-05-13 | `a70f29e` | fix: align symptom logging with database schema |
| 2026-05-13 | `3f2cb9b` | fix: resolve flutter analyze warnings in symptoms views |
| 2026-05-13 | `3ee14ee` | feat: add symptoms feature to feature/monthly-summary base |
| 2026-05-13 | `d26d100` | fix: remove redundant ProviderScope and use service locator in monthly summary |
| 2026-05-13 | `724b064` | fix: resolve calendar status bug, null safety, and immutability issues |
| 2026-05-13 | `e0584dc` | fix: navigate to home after signup and fix isLoggedIn session check |
| 2026-05-13 | `8135350` | feat: implement delete medications feature |
| 2026-05-15 | `08fd8bf` | Optimize CI: targeted tests on PRs, PR comment, full suite on merge to main |
| 2026-05-15 | `2e0c9e1` | feat: implement ClinicGO logo component; add 'with food' option to medication models and views |
| 2026-05-15 | `(current)` | fix: restore 7 skipped home-screen tests and fix supabase mock for fetchMedications |

---

## 3. Prompts Used

Prompts were entered conversationally via the Claude Code CLI interface. The following table documents each interaction session with the representative prompt that triggered the AI-generated work.

### 3.1 Architecture & Core Features

| PBI | Prompt | Outcome |
|---|---|---|
| — | *"Restructure the app architecture: migrate domain models, services, and repositories to a use-case-driven pattern. Inspect the current structure first and make the smallest clean change."* | `acee0da` — full architecture refactor |
| — | *"Add a `reminderId` field to `ScheduledDose` so notifications can be cancelled by ID. Also update the Android manifest with `SCHEDULE_EXACT_ALARM` permission."* | `f1e6ebb` — reminderId + manifest |
| — | *"Implement a 'Today's Doses' section in `MedicationsListScreen`. Show each scheduled dose for today with a Taken/Skip button. Update the dose log schema to store the log date."* | `e60dd57` — today's doses section |
| — | *"Update the overdue dose button text to match the new design. Remove any debug buttons or unused code from the home screen."* | `e39fdd9` — overdue button text cleanup |

### 3.2 Refactors & Fixes

| PBI | Prompt | Outcome |
|---|---|---|
| — | *"Rename the app package from the current name. Update the medication repository so `addMedication` returns the saved medication ID and reminder IDs, so the notification scheduler can use them."* | `7f5c985` — package rename + repo IDs |
| — | *"Improve the legibility of the main menu and home screen. Fix any layout or typography issues that make the content hard to read."* | `371b80d` — home screen legibility |
| — | *"Fix the broken test mocks for the medication repository. The tests are failing because the mock stubs don't match the current method signatures."* | `13d4797` — test mocks fix |
| — | *"Fix: align symptom logging with the current database schema. The `log_symptom` call is sending fields that don't exist in the table."* | `a70f29e` — symptom DB alignment |
| — | *"Run `flutter analyze` and fix all warnings in the symptoms views."* | `3f2cb9b` — analyze warnings |
| — | *"There's a redundant `ProviderScope` in the monthly summary screen. Remove it and use the existing service locator pattern instead."* | `d26d100` — ProviderScope fix |
| — | *"Fix the calendar status calculation bug. There are also null safety warnings and some mutable state that should be immutable."* | `724b064` — calendar bug + null safety |
| — | *"After signing up, the app stays on the sign-up screen. Fix navigation to go home. Also fix `isLoggedIn` — it returns false when the session is actually valid."* | `e0584dc` — signup navigation fix |

### 3.3 Feature Integration

| PBI | Prompt | Outcome |
|---|---|---|
| #99 | *"On the `feature/monthly-summary` branch, integrate the symptoms feature. The symptoms screen should be reachable from the monthly summary."* | `3ee14ee` — symptoms in monthly summary |
| #100 | *"Implement the delete medication feature. Add a delete button to the medication card and wire it to the repository's `deleteMedication` method."* | `8135350` — delete medications |
| #104 | *"Implement ClinicGO logo component and integrate into the main screen header. Also add a 'with food' toggle to the Add Medication form and persist it in the model."* | `2e0c9e1` — logo + withFood field |

### 3.4 Tests

| PBI | Prompt | Outcome |
|---|---|---|
| — | *"Add unit and widget tests for the calendar feature. Cover the view model, the repository mock, and the main widget states."* | `ca3eeda` — calendar tests |
| — | *"Increase test coverage across auth (sign-in, sign-up), profile view, and app startup routing."* | `7389682`, `2b5bded` — auth/profile/routing tests |
| — | *"and the 7 skiped test?" / "ffix them"* — fix all 7 tests marked `skip: true` after the home UI redesign | `(current)` — skipped tests restored |
| — | *"3 testes falham"* — fix the 3 failing supabase repository tests | `(current)` — supabase mock fix (`select('*, medication_reminders(*)')`) |

### 3.5 CI/CD

| PBI | Prompt | Outcome |
|---|---|---|
| — | *"Optimize the CI pipeline: run only the affected tests on pull requests and add a PR comment with results. Run the full suite only on merge to main."* | `08fd8bf` — CI optimization |

---

## 4. PBIs to Label as "MisterAI"

The following GitHub issues had AI-generated code committed as part of their implementation. Apply the `MisterAI` label to each:

| Issue | Title (approximate) |
|---|---|
| #97 | Calendar feature |
| #98 | Monthly summary feature |
| #99 | Symptoms feature |
| #100 | Delete medications |
| #104 | Medication card visual redesign / logo / withFood |
| #115 | Home UI redesign (AI-assisted fixes on top of human refactor) |

> Issues without a number correspond to work done directly on non-issue branches (architecture refactors, CI, test improvements). These are tracked solely by the `[MISTER AI]` commit prefix.

---

## 5. Interaction Model

All prompts were entered as natural language in the Claude Code CLI terminal inside VSCode. The AI:

1. **Read** the relevant source files before making changes.
2. **Proposed** a plan when the task was non-trivial (e.g., architecture refactor, CI setup).
3. **Implemented** changes directly in the repo files using Edit/Write tools.
4. **Ran** `flutter analyze` and `flutter test` to verify correctness before reporting done.
5. **Committed** the resulting changes in an isolated commit with the `[MISTER AI]` prefix.

Human review was performed after each AI session before merging to `main`.
