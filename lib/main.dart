import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:four_u_app/ui/core/themes/app_colors.dart';
import 'package:four_u_app/ui/background/view_models/app_background.dart';
import 'package:four_u_app/ui/common/widgets/custom_search_bar.dart';
import 'package:four_u_app/ui/common/widgets/floating_bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sb_publishable_e-bQdp8wGizIL1py2JMrSg_3GZtj_Lz.supabase.co',
    anonKey: 'sb_secret_8-OsrH4yDDnRHgOHj4Ls3Q_HNovhjgC',
  );
  runApp(const ClinicGO());
}

class ClinicGO extends StatelessWidget {
  const ClinicGO({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClinicGO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // Home as default

  // Lista de ecrãs para navegação
  final List<Widget> _pages = [
    const Center(child: Text("Perfil")),
    const Center(child: Text("Favoritos")),
    const HomeContent(),
    const Center(child: Text("Calendário")),
    const Center(child: Text("Definições")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AppBackground(child: _pages[_currentIndex]),

          // Barra de Pesquisa fixa no topo apenas na Home
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
    return const Center(child: Text("Bem-vindo à ClinicGO!"));
  }
}
