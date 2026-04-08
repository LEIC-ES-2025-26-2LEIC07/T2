# Changelog

## [v0](https://github.com/LEIC-ES-2024-25/2LEIC06T1/releases/tag/v0) - 2026/04/8

### Added


#### Release v0: Foundation & Core Navigation

* **App Architecture (MVVM Pattern):** Established a modular directory structure under `lib/ui/` with a strict separation between **Views** and **ViewModels**. This ensures UI and business logic remain decoupled as the system scales.
* **Database Configuration (Supabase):** Integrated **Supabase** for backend services. Successfully initialized the `supabase_flutter` plugin in the `main()` method with API URL and anonymous key configurations.
* **Navigation Flow & Mock Pages:** Created dummy screens to test application flow, including dedicated views for **Profile**, **Favorites**, and **Home**, with placeholders for **Calendar** and **Settings**.
* **State-Based Routing:** Implemented a central `MainScreen` controller that manages page transitions using a reactive `_currentIndex` state to switch between active modules.
* **Custom Navigation Components:** Developed a **FloatingBottomNavBar** for seamless page switching and a **CustomSearchBar** specific to the Home module.
* **Unified Visual Theme:** Configured **Material 3** with a centralized color scheme derived from `AppColors.primaryColor`. Implemented a reusable `AppBackground` wrapper to maintain visual consistency across all screens.
* **Reusable UI Foundation:** Built a library of foundational mock widgets (Search Bar, Bottom Nav) to serve as the building blocks for upcoming feature development.
