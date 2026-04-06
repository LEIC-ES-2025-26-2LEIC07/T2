import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinic_go/ui/core/themes/app_colors.dart';
import 'package:clinic_go/ui/auth/view_models/auth_view_model.dart';
import 'package:clinic_go/ui/auth/views/auth_wrapper.dart';
import 'package:clinic_go/ui/background/view_models/app_background.dart';
import 'package:clinic_go/ui/common/widgets/custom_search_bar.dart';
import 'package:clinic_go/ui/common/widgets/floating_bottom_nav_bar.dart';
import 'package:clinic_go/ui/profile/views/profile_view.dart';
import 'package:clinic_go/ui/favorites/views/favorites_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Supabase credentials from the bundled .env asset.
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['NEXT_PUBLIC_SUPABASE_URL']!,
    anonKey: dotenv.env['SB_PV_KEY']!,
  );

  runApp(const ClinicGO());
}

class ClinicGO extends StatelessWidget {
  const ClinicGO({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthViewModel())],
      child: MaterialApp(
        title: 'ClinicGO',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
        ),
        home: const AuthWrapper(authenticatedChild: MainScreen()),
      ),
    );
  }
}

// ── Main shell (shown after authentication) ────────────────────────────────────

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // Home as default

  final List<Widget> _pages = [
    const ProfileView(),
    const FavoritesView(),
    const HomeContent(),
    const Center(child: Text('Calendário')),
    const Center(child: Text('Definições')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AppBackground(child: _pages[_currentIndex]),

          // Search bar — fixed at top only on the Home tab.
          if (_currentIndex == 2)
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: CustomSearchBar(),
              ),
            ),

          FloatingBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Bem-vindo à ClinicGO!'));
  }
}
