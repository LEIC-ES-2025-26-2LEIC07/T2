# Project Testing Overview

This document describes the features and flows currently covered by the project's test suite, associated with their respective test files.

## 1. Core Architecture & Infrastructure
- **Feature-based Organization**: Verification of the `lib/features/` and `lib/core/` structure.
- **Dependency Injection & App Bootstrapping**: Initialization logic in `main.dart`.
    - **Associated File**: `test/unit_test/widget_test.dart`

## 2. Authentication & Profile
- **Login Logic**: Verification of authentication states and user login flows.
    - **Associated File**: `test/unit_test/login_view_model_test.dart`
- **UI Smoke Test**: Basic verification of the app's entry point and home screen.
    - **Associated File**: `test/unit_test/widget_test.dart`

## 3. Medication Management & Dose Logging
- **Flow Validation**: End-to-end process of viewing and logging a medication dose.
    - **Associated File**: `integration_test/app_test.dart`
- **Data Persistence**: Interaction with the Dose Log repository.
    - **Associated File**: `test/integration_test/app_test.dart`

## 4. Notification System
- **Deep Linking & Interaction**: Verification that interacting with a notification routes the user to the correct dose logging screen.
    - **Associated File**: `integration_test/notification_flow_test.dart`
- **Background Syncing**: Lifecycle handling for notification synchronization.
    - **Associated File**: `integration_test/notification_flow_test.dart`

## 5. UI & UX
- **Navigation**: Ensuring all primary routes and navigation bars function as expected.
    - **Associated File**: `test/integration_test/app_test.dart`
- **Theme & Design**: Application of the "ClinicGO" theme and color palette.
    - **Associated File**: `test/unit_test/widget_test.dart`

---

## Test Execution Summary

| Test Type | File Path | Purpose |
| :--- | :--- | :--- |
| **Integration** | `integration_test/notification_flow_test.dart` | Tests Notification deep-linking and dose logging flow. |
| **Integration** | `test/integration_test/app_test.dart` | Tests overall app navigation and core UI interactions. |
| **Unit** | `test/unit_test/login_view_model_test.dart` | Tests business logic for user authentication. |
| **Unit/Widget** | `test/unit_test/widget_test.dart` | Basic smoke tests for UI components and theme. |

**Status**: All tests are confirmed to pass locally.
