# Changelog

## [v0](https://github.com/LEIC-ES-2024-25/2LEIC06T1/releases/tag/v0) - 2025/03/28

### Added

Here is the organized and polished text formatted perfectly for your **v0 Release Notes** or `README.md` file. I have adjusted the phrasing slightly to sound like official release documentation rather than a code review, utilizing Markdown for clear scannability.

### Release v0: Foundation & Core Navigation

**1. App Architecture (MVVM Pattern)**
The project is set up using a modular directory structure under the `lib/ui/` folder, separating the app by features such as `profile`, `favorites`, `background`, and `common`. Inside these feature folders, there is a clear separation between views and view models (e.g., `views/profile_view.dart` and `view_models/app_background.dart`), which establishes the foundations of the **Model-View-ViewModel (MVVM)** design pattern. This ensures that UI logic and business logic are kept appropriately separate as the app scales.

**2. Database Configuration (Supabase)**
Backend infrastructure has been established using **Supabase** (an open-source Firebase alternative). It is successfully initialized in the app's `main()` method with an API URL and an anonymous key using the `supabase_flutter` plugin, preparing the app for secure data storage and authentication.

**3. Mock Pages for Navigation Flow**
Dummy screens have been created to establish and test the app's structural flow. These are defined inside a `_pages` list in the `MainScreen`, incorporating mock implementation pages such as:
* A Profile view (`ProfileView`)
* A Favorites view (`FavoritesView`)
* A Home view (`HomeContent` reading "Bem-vindo à ClinicGO!")
* Placeholder mock pages using simple `Text` widgets for the "Calendário" (Calendar) and "Definições" (Settings) pages.

**4. Router and Navigation Setup**
Simple state-based routing has been successfully implemented. The `MainScreen` is a Stateful Widget that uses an internal `_currentIndex` variable (defaulted to `2` for the Home screen) to manage navigation. It switches out the visible screen from the `_pages` array whenever a navigation event is triggered.

**5. Navigation Bar**
To trigger page transitions, a custom navigation bar—`FloatingBottomNavBar`—has been implemented at the bottom of the screen. Tapping an item updates the `_currentIndex`, changing the page seamlessly. On the Home Screen specifically, an additional `CustomSearchBar` appears at the top.

**6. Main App Theme**
The app is configured with **Material 3** enabled, providing modern Android and iOS UI styling out of the box. Additionally, a central color theme is established in `ThemeData` using `ColorScheme.fromSeed`, seeded by the centralized `AppColors.primaryColor`. A reusable `AppBackground` has been wrapped around the content, guaranteeing a unified visual background aesthetic throughout the application.

**7. Mock Widgets**
Foundational common UI elements have been built and included, especially on the Home page. Reusable components like a custom top search bar (`CustomSearchBar`) and the floating bottom navigation area (`FloatingBottomNavBar`) lay the groundwork for building out the rest of the application's interface.