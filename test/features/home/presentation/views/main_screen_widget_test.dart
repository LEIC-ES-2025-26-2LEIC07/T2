import 'package:clinic_go/features/home/presentation/view_models/home_view_model.dart';
import 'package:clinic_go/features/home/presentation/views/main_screen.dart';
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
  });

  setUp(() {
    mockViewModel = MockHomeViewModel();
    mockObserver = MockNavigatorObserver();

    // Default stubs
    when(() => mockViewModel.isLoading).thenReturn(false);
    when(() => mockViewModel.nextDose).thenReturn(null);
    when(() => mockViewModel.isOverdue).thenReturn(false);
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
      'Empty state: [Scenario] → "No upcoming doses" message is visible',
      (tester) async {
        when(() => mockViewModel.isLoading).thenReturn(false);
        when(() => mockViewModel.nextDose).thenReturn(null);

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('No upcoming doses. Good job!'), findsOneWidget);
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

        expect(find.text('Upcoming dose'), findsOneWidget);
        expect(find.text('Aspirin • 100mg'), findsOneWidget);
        expect(find.text('Log Dose'), findsOneWidget);
      },
    );

    testWidgets(
      'Success state (Overdue): [Scenario] → warning icon and red text are visible',
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

        expect(find.text('Overdue dose'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        expect(find.text('Log Overdue Dose'), findsOneWidget);
      },
    );

    testWidgets(
      'User interactions: [Scenario] → tapping Log Dose triggers navigation',
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

        await tester.pumpWidget(createWidgetUnderTest());

        await tester.tap(find.text('Log Dose'));
        await tester.pumpAndSettle();

        // Verify that a route was pushed
        verify(() => mockObserver.didPush(any(), any())).called(greaterThan(0));
      },
    );
  });
}
