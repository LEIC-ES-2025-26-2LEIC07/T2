# Changelog

## [v0.2](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/releases/tag/v0.2) - 2026-05-13

### Added

- Monthly medication summary so users can review their medication intake over time. [#28](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/28)
- Calendar schedule view for past and upcoming medication doses. [#91](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/91)
- Symptom logging flow so users can record symptoms and help doctors monitor health condition changes. [#46](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/46)
- Profile update flow so users can keep personal information and preferences up to date. [#92](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/92)
- Daily doses flow so users can see today's scheduled medication doses and act on them from the app. [#29](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/29)
- Additional automated tests for authentication, medication data, notifications, calendar, monthly summaries, profile updates, and symptoms.

### Changed

- Improved main menu, home screen legibility, and navigation between the main ClinicGO areas.
- Updated medication repository behavior to return saved medication IDs, supporting reminder scheduling.
- Updated app package structure and configuration to use the ClinicGO identity consistently.
- Expanded routing to support medication, calendar, profile, and symptom flows.

### Fixed

- Fixed Supabase integration issues affecting authentication and medication data flows.
- Fixed formatting, typos, and minor UI inconsistencies found after v0.1.
- Fixed schema alignment issues in symptom logging.

### What's Changed

- Implemented monthly summary, calendar, and symptoms features.
- Added login and registration screens with authentication logic.
- Enhanced authentication flow with routing and success state management.
- Added and expanded tests for the main app flows.

Full Changelog: [v0.1...v0.2](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/compare/v0.1...v0.2)

-----

## [v0.1](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/releases/tag/v0.1) - 2026-04-22

### Added

- Receive notifications if medication is missed to intervene when necessary. [#43](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/43)
- Add specific medications with dosage and frequency for accurate reminders. [#63](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/63)
- Mark medication doses as taken or skipped to track treatment and avoid missing doses. [#29](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/29)

### Fixed

- Enable secure login with email and password to access personalized profile and settings. [#45](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/45)

### What's Changed

- Background added by @guizas-LA in [#78](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/pull/78)
- Login menu created by @guizas-LA in [#79](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/pull/79)
- Improved design by @guizas-LA in [#80](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/pull/80)
- Login and Profile update by @Dab1d in [#84](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/pull/84)
- Feature medication by @Dab1d in [#85](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/pull/85)
- Notifications tests by @Dab1d and @JoaooM26 in [#86](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/pull/86)

Full Changelog: [v0...v0.1](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/compare/v0...v0.1)

-----

## [v0](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/releases/tag/v0) - 2026-04-08

### Added

- Bottom navigation and state-based routing so users can move between the main app areas from a single shell. [#22](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/22)
- Home to Profile navigation flow, giving users access to their personal area from the main screen. [#37](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/37)
- Initial profile screen structure for future account and preference management. [#92](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/92)
- Placeholder flows for monthly medication summaries, symptom logging, medical history, calendar schedule, and medication stock progress. [#28](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/28), [#46](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/46), [#49](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/49), [#51](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/51), [#91](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/91)
- Supabase configuration as the backend foundation for secure authentication and personalized data. [#45](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/45)
- Unified Material 3 visual theme with reusable app background and navigation components.
- Initial MVVM-based project structure separating views, view models, services, repositories, and shared widgets.

### Fixed

- Stabilized the first account creation path to reduce crashes during early registration testing. [#89](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/89)

### What's Changed

- Established the first usable ClinicGO app shell with navigation, profile access, backend setup, and UI foundations.
- Added the first release snapshot of project documentation, diagrams, Sprint 0 board evidence, and validation notes.
- Prepared the product backlog implementation path for upcoming medication reminders, dose logging, summaries, calendar, and profile features.

Full Changelog: [v0](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/releases/tag/v0)


-----
