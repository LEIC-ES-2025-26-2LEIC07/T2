import 'package:clinic_go/features/home/presentation/view_models/home_view_model.dart';
import 'package:clinic_go/features/home/presentation/widgets/home_next_dose_card.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeViewModel extends Mock implements HomeViewModel {}

void main() {
  late MockHomeViewModel mockViewModel;

  setUpAll(() {
    registerFallbackValue(
      ScheduledDose(
        id: '',
        medicationId: '',
        medicationName: '',
        dosage: '',
        scheduledTime: DateTime(2000),
      ),
    );
    registerFallbackValue(DoseLogStatus.taken);
  });

  setUp(() {
    mockViewModel = MockHomeViewModel();
    when(() => mockViewModel.isLoading).thenReturn(false);
    when(() => mockViewModel.hadDosesToday).thenReturn(false);
    when(() => mockViewModel.isLoggingDose).thenReturn(false);
  });

  Widget buildCard({
    ScheduledDose? nextDose,
    bool isOverdue = false,
    DateTime? now,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: HomeNextDoseCard(
          viewModel: mockViewModel,
          nextDose: nextDose,
          isOverdue: isOverdue,
          now: now ?? DateTime(2026, 5, 22, 10, 0),
          onGoToDailyDoses: () {},
        ),
      ),
    );
  }

  group('HomeNextDoseCard', () {
    testWidgets(
      'null nextDose + hadDosesToday false → shows "Sem doses agendadas."',
      (tester) async {
        when(() => mockViewModel.hadDosesToday).thenReturn(false);
        await tester.pumpWidget(buildCard(nextDose: null));
        expect(find.text('Sem doses agendadas.'), findsOneWidget);
      },
    );

    testWidgets(
      'null nextDose + hadDosesToday true → shows "Tudo feito por hoje!"',
      (tester) async {
        when(() => mockViewModel.hadDosesToday).thenReturn(true);
        await tester.pumpWidget(buildCard(nextDose: null));
        expect(find.text('Tudo feito por hoje!'), findsOneWidget);
      },
    );

    testWidgets('upcoming dose → shows PRÓXIMA DOSE, med name, "Agendado às"', (
      tester,
    ) async {
      final dose = ScheduledDose(
        id: 'd1',
        medicationId: 'm1',
        medicationName: 'Aspirin',
        dosage: '100mg',
        scheduledTime: DateTime(2026, 5, 22, 14, 30),
      );
      await tester.pumpWidget(buildCard(nextDose: dose, isOverdue: false));
      expect(find.text('PRÓXIMA DOSE'), findsOneWidget);
      expect(find.text('Aspirin 100mg'), findsOneWidget);
      expect(find.textContaining('Agendado às'), findsOneWidget);
    });

    testWidgets('overdue dose → shows EM ATRASO badge and "Era às"', (
      tester,
    ) async {
      final now = DateTime(2026, 5, 22, 10, 45);
      final dose = ScheduledDose(
        id: 'd1',
        medicationId: 'm1',
        medicationName: 'Ibuprofen',
        dosage: '200mg',
        scheduledTime: DateTime(2026, 5, 22, 10, 0),
      );
      await tester.pumpWidget(
        buildCard(nextDose: dose, isOverdue: true, now: now),
      );
      expect(find.textContaining('EM ATRASO'), findsOneWidget);
      expect(find.textContaining('Era às'), findsOneWidget);
    });

    testWidgets(
      'isLoggingDose true → shows loading indicator, logDose not invoked',
      (tester) async {
        when(() => mockViewModel.isLoggingDose).thenReturn(true);
        final dose = ScheduledDose(
          id: 'd1',
          medicationId: 'm1',
          medicationName: 'Aspirin',
          dosage: '100mg',
          scheduledTime: DateTime(2026, 5, 22, 14, 0),
        );
        await tester.pumpWidget(buildCard(nextDose: dose));
        // When loading, "Tomar agora" text is replaced by CircularProgressIndicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Tomar agora'), findsNothing);
        verifyNever(
          () => mockViewModel.logDose(
            dose: any(named: 'dose'),
            status: any(named: 'status'),
          ),
        );
      },
    );

    testWidgets('tapping Tomar agora calls logDose with status taken', (
      tester,
    ) async {
      final dose = ScheduledDose(
        id: 'd1',
        medicationId: 'm1',
        medicationName: 'Aspirin',
        dosage: '100mg',
        scheduledTime: DateTime(2026, 5, 22, 14, 0),
      );
      when(
        () => mockViewModel.logDose(
          dose: any(named: 'dose'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildCard(nextDose: dose));
      await tester.tap(find.text('Tomar agora'));
      await tester.pump();

      verify(
        () => mockViewModel.logDose(
          dose: any(named: 'dose'),
          status: DoseLogStatus.taken,
        ),
      ).called(1);
    });

    testWidgets('tapping Saltar calls logDose with status skipped', (
      tester,
    ) async {
      final dose = ScheduledDose(
        id: 'd1',
        medicationId: 'm1',
        medicationName: 'Aspirin',
        dosage: '100mg',
        scheduledTime: DateTime(2026, 5, 22, 14, 0),
      );
      when(
        () => mockViewModel.logDose(
          dose: any(named: 'dose'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildCard(nextDose: dose));
      await tester.tap(find.text('Saltar'));
      await tester.pump();

      verify(
        () => mockViewModel.logDose(
          dose: any(named: 'dose'),
          status: DoseLogStatus.skipped,
        ),
      ).called(1);
    });
  });
}
