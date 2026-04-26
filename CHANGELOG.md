# Changelog

## [v0](https://github.com/LEIC-ES-2024-25/2LEIC06T1/releases/tag/v0) - 2026/04/8

### Added

-----

### Release v0: Foundation & Core Navigation

  * **App Architecture (MVVM Pattern) [[\#22](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/22)]:** Established a modular directory structure under `lib/ui/` with a strict separation between **Views** and **ViewModels**. This architecture provides the core routing structure needed for the entire app.
  * **Database Configuration (Supabase) [[\#45](https://www.google.com/search?q=https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/45)]:** Integrated **Supabase** as the primary backend provider. Successfully initialized the `supabase_flutter` plugin in the `main()` method, setting the stage for secure authentication and cloud data storage.
  * **Navigation Flow & Mock Pages [[\#37](https://www.google.com/search?q=https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/37), [\#22](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/22)]:** Created functional screens to test application flow, including **Profile (\#37)** and **Home**, with placeholders for **Calendar (\#48)** and **Settings**.
  * **State-Based Routing [[\#22](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/22)]:** Implemented a central `MainScreen` controller that manages page transitions using a reactive `_currentIndex` state, allowing for modular switching between active features.
  * **Custom Navigation Components [[\#22](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/22), [\#51](https://www.google.com/search?q=https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/51)]:** Developed the **FloatingBottomNavBar (\#22)** for global navigation and a **CustomSearchBar** to lay the groundwork for future search and stock filtering logic **(\#51)**.
  * **Unified Visual Theme [[\#71](https://www.google.com/search?q=https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/71)]:** Configured **Material 3** with a centralized color scheme. This includes a reusable **AppBackground** and UI wrappers that will house future elements like the **Medical Disclaimer (\#71)**.
  * **Reusable UI Foundation [[\#22](https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/22), [\#67](https://www.google.com/search?q=https://github.com/LEIC-ES-2025-26-2LEIC07/T2/issues/67)]:** Built a library of foundational mock widgets. These components provide the UI hooks necessary for upcoming hardware integrations like the **Native Camera (\#67)**.

-----
