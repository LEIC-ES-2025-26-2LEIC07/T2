import 'package:clinic_go/app.dart';
import 'package:clinic_go/ui/symptoms/view_models/symptom_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    try {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        anonKey: 'public-anon-key',
      );
    } catch (_) {}
  });

  group('ClinicGoApp', () {
    testWidgets('renders the router app shell', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: ClinicGoApp()));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Track how you feel'), findsOneWidget);
      expect(find.text('Log symptom'), findsWidgets);
    });
  });

  group('SymptomFormController', () {
    test('requires a selected symptom before submit', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(symptomFormControllerProvider.notifier);

      final success = await controller.submitSymptomLog();
      final state = container.read(symptomFormControllerProvider);

      expect(success, isFalse);
      expect(state.errorMessage, 'Sign in to save a symptom log.');
    });

    test('marks the form dirty after user input', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(symptomFormControllerProvider.notifier);

      controller.selectSymptom('headache');
      controller.setSeverity(7);
      controller.setNotes('Started after lunch');

      final state = container.read(symptomFormControllerProvider);

      expect(state.isDirty, isTrue);
      expect(state.selectedSymptom, 'headache');
      expect(state.severity, 7);
      expect(state.notes, 'Started after lunch');
    });
  });
}
