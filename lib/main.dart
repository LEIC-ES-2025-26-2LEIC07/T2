import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/ui/core/themes/app_colors.dart';
import 'package:clinic_go/ui/background/view_models/app_background.dart';
import 'package:clinic_go/ui/common/widgets/custom_search_bar.dart';
import 'package:clinic_go/ui/common/widgets/floating_bottom_nav_bar.dart';
import 'package:clinic_go/ui/profile/views/profile_view.dart';
import 'package:clinic_go/ui/favorites/views/favorites_view.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/supabase_dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';
import 'package:clinic_go/features/medication/services/missed_dose_notification_controller.dart';
import 'package:clinic_go/features/medication/services/pending_notification_store.dart';
import 'package:clinic_go/features/medication/views/dose_logging_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sb_publishable_e-bQdp8wGizIL1py2JMrSg_3GZtj_Lz.supabase.co',
    anonKey: 'sb_secret_8-OsrH4yDDnRHgOHj4Ls3Q_HNovhjgC',
  );
  runApp(
    ClinicGO(
      notificationController: MissedDoseNotificationController(
        notificationGateway: const NoopLocalNotificationGateway(),
        doseLogRepository: SupabaseDoseLogRepository(Supabase.instance.client),
        pendingNotificationStore: const PendingNotificationStore(),
      ),
    ),
  );
}

class ClinicGO extends StatefulWidget {
  const ClinicGO({super.key, this.notificationController});

  final MissedDoseNotificationController? notificationController;

  @override
  State<ClinicGO> createState() => _ClinicGOState();
}

class _ClinicGOState extends State<ClinicGO> {
  @override
  void initState() {
    super.initState();
    widget.notificationController?.syncPendingMissedNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClinicGO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
      ),
      onGenerateRoute: (settings) =>
          _buildRoute(settings, widget.notificationController),
      home: MainScreen(notificationController: widget.notificationController),
    );
  }
}

Route<dynamic>? _buildRoute(
  RouteSettings settings,
  MissedDoseNotificationController? controller,
) {
  final routeName = settings.name;
  if (routeName == null || !routeName.startsWith('/log-dose/')) {
    return null;
  }

  final uri = Uri.parse(routeName);
  final doseId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
  if (doseId == null || controller == null) {
    return null;
  }

  final scheduledTime = DateTime.tryParse(
    uri.queryParameters['scheduledTime'] ?? '',
  );
  final medicationId = uri.queryParameters['medicationId'];
  final medicationName = uri.queryParameters['medicationName'];
  final dosage = uri.queryParameters['dosage'];
  if (scheduledTime == null ||
      medicationId == null ||
      medicationName == null ||
      dosage == null) {
    return null;
  }

  final dose = ScheduledDose(
    id: doseId,
    medicationId: medicationId,
    medicationName: medicationName,
    dosage: dosage,
    scheduledTime: scheduledTime,
  );

  return MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => DoseLoggingScreen(
      dose: dose,
      controller: controller,
      isOverdue: uri.queryParameters['status'] == 'overdue',
    ),
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.notificationController});

  final MissedDoseNotificationController? notificationController;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // Home as default

  // Lista de ecrãs para navegação
  final List<Widget> _pages = [
    const ProfileView(),
    const FavoritesView(),
    const HomeContent(),
    const Center(child: Text("Calendário")),
    const Center(child: Text("Definições")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AppBackground(
            child: _currentIndex == 2
                ? HomeContent(
                    notificationController: widget.notificationController,
                  )
                : _pages[_currentIndex],
          ),

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
  const HomeContent({super.key, this.notificationController});

  final MissedDoseNotificationController? notificationController;

  ScheduledDose get _demoDose => ScheduledDose(
    id: 'demo-dose-08-00',
    medicationId: 'med-1',
    medicationName: 'Lisinopril',
    dosage: '10 mg',
    scheduledTime: DateTime(2026, 4, 16, 8),
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 120),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Bem-vindo à ClinicGO!"),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming dose',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('${_demoDose.medicationName} • ${_demoDose.dosage}'),
                  const SizedBox(height: 4),
                  const Text('Scheduled for 08:00'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: notificationController == null
                        ? null
                        : () {
                            Navigator.of(context).pushNamed(
                              MissedDoseNotificationController.buildDoseLoggingRoute(
                                _demoDose,
                                isOverdue: true,
                              ),
                            );
                          },
                    child: const Text('Open overdue dose'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
