import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/features/doses/data/dose_log_repository.dart';
import 'package:clinic_go/features/doses/models/scheduled_dose.dart';
import 'package:clinic_go/features/doses/view_models/daily_doses_controller.dart';
import 'package:clinic_go/features/doses/views/medication_dashboard_view.dart';
import 'package:clinic_go/ui/core/themes/app_colors.dart';
import 'package:clinic_go/ui/background/view_models/app_background.dart';
import 'package:clinic_go/ui/common/widgets/custom_search_bar.dart';
import 'package:clinic_go/ui/common/widgets/floating_bottom_nav_bar.dart';
import 'package:clinic_go/ui/profile/views/profile_view.dart';
import 'package:clinic_go/ui/favorites/views/favorites_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sb_publishable_e-bQdp8wGizIL1py2JMrSg_3GZtj_Lz.supabase.co',
    anonKey: 'sb_secret_8-OsrH4yDDnRHgOHj4Ls3Q_HNovhjgC',
  );
  runApp(
    ClinicGO(
      doseLogRepository: SupabaseDoseLogRepository(Supabase.instance.client),
    ),
  );
}

class ClinicGO extends StatelessWidget {
  const ClinicGO({super.key, this.doseLogRepository});

  final DoseLogRepository? doseLogRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClinicGO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
      ),
      home: MainScreen(
        doseLogRepository: doseLogRepository ?? const NoopDoseLogRepository(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.doseLogRepository});

  final DoseLogRepository? doseLogRepository;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // Home as default
  late final DailyDosesController _dailyDosesController;

  @override
  void initState() {
    super.initState();
    _dailyDosesController = DailyDosesController(
      repository: widget.doseLogRepository ?? const NoopDoseLogRepository(),
      initialDoses: _buildInitialDoses(),
    );
  }

  @override
  void dispose() {
    _dailyDosesController.dispose();
    super.dispose();
  }

  List<Widget> get _pages => [
    const ProfileView(),
    const FavoritesView(),
    HomeContent(controller: _dailyDosesController),
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
  const HomeContent({super.key, required this.controller});

  final DailyDosesController controller;

  @override
  Widget build(BuildContext context) {
    return MedicationDashboardView(controller: controller);
  }
}

List<ScheduledDose> _buildInitialDoses() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return [
    ScheduledDose(
      id: 'dose-1',
      medicationId: 'med-1',
      medicationName: 'Lisinopril',
      dosage: '10 mg tablet',
      instructions: 'Take with water after breakfast.',
      scheduledTime: today.add(const Duration(hours: 8)),
    ),
    ScheduledDose(
      id: 'dose-2',
      medicationId: 'med-2',
      medicationName: 'Metformin',
      dosage: '500 mg tablet',
      instructions: 'Take with food to avoid stomach discomfort.',
      scheduledTime: today.add(const Duration(hours: 13)),
    ),
    ScheduledDose(
      id: 'dose-3',
      medicationId: 'med-3',
      medicationName: 'Vitamin D',
      dosage: '1 capsule',
      instructions: 'Best taken with lunch or a meal containing fat.',
      scheduledTime: today.add(const Duration(hours: 20, minutes: 30)),
    ),
  ];
}
