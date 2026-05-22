import 'package:clinic_go/features/home/presentation/view_models/home_view_model.dart';
import 'package:clinic_go/features/home/presentation/views/home_content.dart';
import 'package:clinic_go/features/medication/data/dose_log_repository.dart';
import 'package:clinic_go/features/medication/models/scheduled_dose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeViewModel extends Mock implements HomeViewModel {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  late MockHomeViewModel mockViewModel;
  late MockNavigatorObserver mockObserver;

  setUpAll(() {
    registerFallbackValue(FakeRoute());
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
    mockObserver = MockNavigatorObserver();

    // Default stubs
    when(() => mockViewModel.isLoading).thenReturn(false);
    when(() => mockViewModel.nextDose).thenReturn(null);
    when(() => mockViewModel.isOverdue).thenReturn(false);
    when(() => mockViewModel.isLoggingDose).thenReturn(false);
    when(() => mockViewModel.todayDoses).thenReturn([]);
    when(() => mockViewModel.hadDosesToday).thenReturn(false);
    when(() => mockViewModel.loadNextDose()).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(body: HomeContent(viewModel: mockViewModel)),
      navigatorObservers: [mockObserver],
      // Re-add onGenerateRoute to handle the push in the test environment
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => Scaffold(body: Text('Navigated to ${settings.name}')),
      ),
    );
  }

  group('HomeContent Widget Tests', () {
    testWidgets('Loading state: [Scenario] → spinner is visible', (
      tester,
    ) async {
      when(() => mockViewModel.isLoading).thenReturn(true);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'Empty state: [Scenario] → "Sem doses agendadas" message is visible',
      (tester) async {
        when(() => mockViewModel.isLoading).thenReturn(false);
        when(() => mockViewModel.nextDose).thenReturn(null);
        when(() => mockViewModel.hadDosesToday).thenReturn(false);

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('Sem doses agendadas.'), findsOneWidget);
      },
    );

    testWidgets(
      'Success state (Upcoming): [Scenario] → dose card is rendered correctly',
      (tester) async {
        final dose = ScheduledDose(
          id: 'd1',
          medicationId: 'm1',
          medicationName: 'Aspirin',
          dosage: '100mg',
          scheduledTime: DateTime(2026, 4, 20, 14, 0),
        );

        when(() => mockViewModel.isLoading).thenReturn(false);
        when(() => mockViewModel.nextDose).thenReturn(dose);
        when(() => mockViewModel.isOverdue).thenReturn(false);

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('PRÓXIMA DOSE'), findsOneWidget);
        expect(find.text('Aspirin 100mg'), findsOneWidget);
        expect(find.text('Tomar agora'), findsOneWidget);
      },
    );

    testWidgets(
      'Success state (Overdue): [Scenario] → overdue badge and Tomar agora are visible',
      (tester) async {
        final dose = ScheduledDose(
          id: 'd1',
          medicationId: 'm1',
          medicationName: 'Aspirin',
          dosage: '100mg',
          scheduledTime: DateTime(2026, 4, 20, 8, 0),
        );

        when(() => mockViewModel.isLoading).thenReturn(false);
        when(() => mockViewModel.nextDose).thenReturn(dose);
        when(() => mockViewModel.isOverdue).thenReturn(true);

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('PRÓXIMA DOSE'), findsOneWidget);
        expect(find.textContaining('EM ATRASO'), findsOneWidget);
        expect(find.text('Tomar agora'), findsOneWidget);
      },
    );

    testWidgets(
      'User interactions: [Scenario] → tapping Tomar agora invokes logDose',
      (tester) async {
        final dose = ScheduledDose(
          id: 'd1',
          medicationId: 'm1',
          medicationName: 'Aspirin',
          dosage: '100mg',
          scheduledTime: DateTime(2026, 4, 20, 14, 0),
        );

        when(() => mockViewModel.isLoading).thenReturn(false);
        when(() => mockViewModel.nextDose).thenReturn(dose);
        when(
          () => mockViewModel.logDose(
            dose: any(named: 'dose'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(createWidgetUnderTest());

        await tester.tap(find.text('Tomar agora'));
        await tester.pump();

        verify(
          () => mockViewModel.logDose(
            dose: any(named: 'dose'),
            status: any(named: 'status'),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'Quick actions: [Scenario] → Registar sintoma and Histórico are visible',
      (tester) async {
        when(() => mockViewModel.isLoading).thenReturn(false);
        when(() => mockViewModel.nextDose).thenReturn(null);
        when(() => mockViewModel.todayDoses).thenReturn([]);

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('Registar sintoma'), findsOneWidget);
        expect(find.text('Histórico'), findsOneWidget);
      },
    );

    testWidgets(
      'All done state: [Scenario] → shows "Tudo feito por hoje!" when hadDosesToday and no nextDose',
      (tester) async {
        when(() => mockViewModel.isLoading).thenReturn(false);
        when(() => mockViewModel.nextDose).thenReturn(null);
        when(() => mockViewModel.hadDosesToday).thenReturn(true);
        when(() => mockViewModel.todayDoses).thenReturn([]);

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('Tudo feito por hoje!'), findsOneWidget);
      },
    );

    testWidgets('Today plan with entries: [Scenario] → renders dose entries', (
      tester,
    ) async {
      final dose = ScheduledDose(
        id: 'd1',
        medicationId: 'm1',
        medicationName: 'Metformina',
        dosage: '500mg',
        scheduledTime: DateTime.now().add(const Duration(hours: 1)),
      );
      final entries = [
        TodayDoseEntry(dose: dose, isPending: true, isOverdue: false),
      ];

      when(() => mockViewModel.isLoading).thenReturn(false);
      when(() => mockViewModel.nextDose).thenReturn(null);
      when(() => mockViewModel.hadDosesToday).thenReturn(true);
      when(() => mockViewModel.todayDoses).thenReturn(entries);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Metformina 500mg'), findsOneWidget);
    });
  });
}
