# Changelog
  ## [v1.0](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/releases/tag/v1.0) - 2026-06-06                                                                                     
                                                                                                                                                                         
### Added                                                                                                                                                                   
                                                                                                                                                                           
- Server-side medication reminder delivery via Supabase Edge Function + pg_cron + Firebase FCM, so reminders fire reliably even when the app is closed. [#135](https://githu
b.com/LEIC-ES-2025-26-2LEIC07/T2/issues/135)                                                                                                                                
- Settings page notifications toggle that reads the real system permission state and persists the user preference across sessions.                                          
                                                                                                                                                                           
### Changed                                                                                                                                                                 
                                                                                                                                                                           
- Medication reminders migrated from client-side `flutter_local_notifications` scheduling to a Supabase Edge Function (`send-medication-reminders`) triggered every minute by pg_cron, which queries due reminders and sends FCM push notifications directly to the device. [#135](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/135)            
                                                                                                                                                                          
### Fixed                                                                                                                                                                   
                                                                                                                                                                          
- Fixed notification not dismissed from the system tray after logging a dose — notification ID mismatch between `show()` and `cancel()` caused the cancel to target the wrong notification.                                                                                                                                                                                     
### What's Changed                                                                                                                                                          
                                                                                                                                                                           
- Migrate medication reminders to server-side Supabase FCM by @Dab1d in fix-notifications                                                                                   
- Settings notifications toggle functional implementation by @Dab1d in fix-notifications

Full Changelog: [v0.3...v0.4](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/compare/v0.3...v0.4)                                                                            
                                                                                                                                                                           
-----                                                                                                                                                                       
                                                                                          

## [v0.3](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/releases/tag/v0.3) - 2026-05-22

### Added

- Avatar photo upload from gallery so users can set a profile picture. [#105](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/105)
- Symptom history view so users can review their previously logged symptoms over time. [#114](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/114)
- Splash screen with ClinicGO branding shown on app launch.
- Notification lifecycle management with runtime permission handling and dose reminder scheduling.
- "With food" option on medications so users can track whether a dose should be taken with a meal. [#104](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/104)
- ClinicGO logo component in the main screen header.
- Expanded automated test suite covering add medication, edit/delete medication, and register user journeys.

### Changed

- Profile screen redesigned to neo-brutalist style with initials avatar, NOME and EMAIL info rows, and distinct edit/logout button layout. [#105](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/105)
- Medication list and card visuals redesigned to match the Clinical Blue design system. [#104](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/104)
- Add medication screen redesigned with dosage split into amount and unit selector fields. [#111](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/111)
- Edit medication screen redesigned to match Clinical Blue mockup. [#112](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/112)
- Login and register screens redesigned in Portuguese with improved layout and validation feedback. [#110](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/110)
- Navigation bar labels translated to Portuguese (PERFIL · MEDS · INÍCIO · PLANO · CONFIG).
- App code structure refactored for improved readability and module separation.

### Fixed

- Fixed ViewModel dispose crash on the medication list and calendar screens when background operations completed after the widget was unmounted.
- Fixed auth status banner on login and sign-up screens to provide clearer feedback on success and error states.
- Fixed integration tests broken by Portuguese redesign; all acceptance test journeys now pass.

### What's Changed

- Profile screen neo-brutalist refactor and avatar upload by @Dab1d in [#105](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/105)
- Symptom history view by @JoaooM26 in [#125](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/pull/125)
- Notification feature by @guizas-LA in [#122](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/pull/122)
- Splash screen and login screen redesign by @Dab1d in [#121](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/pull/121)
- Auth status banner and login/register redesign by @Dab1d in [#120](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/pull/120)
- Edit medication screen redesign by @Dab1d in [#119](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/pull/119)
- Add medication screen redesign by @Dab1d in [#118](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/pull/118)
- Medication card and logo visual refac by @Dab1d in [#116](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/pull/116)
- Code structure refactor by @Dab1d in [#115](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/pull/115)

Full Changelog: [v0.2...v0.3](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/compare/v0.2...v0.3)

-----

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
