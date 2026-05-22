import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/services/local_notification_gateway.dart';
import 'package:clinic_go/features/medication/services/pending_notification_store.dart';
import 'package:clinic_go/features/medication/services/dose_scheduling_service.dart';
import 'package:clinic_go/features/calendar/data/calendar_repository.dart';

void main() {
  setUp(() async => getIt.reset());
  tearDown(() async => getIt.reset());

  group('setupServiceLocator', () {
    test(
      'registers lazy singletons before Supabase resolution fails',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        final key = GlobalKey<NavigatorState>();
        try {
          await setupServiceLocator(key);
        } catch (_) {}

        expect(getIt.isRegistered<SupabaseClient>(), isTrue);
        expect(getIt.isRegistered<AuthService>(), isTrue);
        expect(getIt.isRegistered<DoseLogRepository>(), isTrue);
        expect(getIt.isRegistered<MedicationRepository>(), isTrue);
        expect(getIt.isRegistered<PendingNotificationStore>(), isTrue);
        expect(getIt.isRegistered<DoseSchedulingService>(), isTrue);
        expect(getIt.isRegistered<CalendarRepository>(), isTrue);
        expect(getIt.isRegistered<LocalNotificationGateway>(), isTrue);
      },
    );

    test(
      'notification gateway falls back to NoopLocalNotificationGateway in test env',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        final key = GlobalKey<NavigatorState>();
        try {
          await setupServiceLocator(key);
        } catch (_) {}

        if (getIt.isRegistered<LocalNotificationGateway>()) {
          final gateway = getIt<LocalNotificationGateway>();
          expect(gateway, isA<NoopLocalNotificationGateway>());
        }
      },
    );
  });
}
