import 'package:clinic_go/main.dart' as app;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smoke Test', () {
    testWidgets('Verify app starts and shows dashboard', (tester) async {
      SharedPreferences.setMockInitialValues({});

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.llfbandit.app_links/events'),
        (methodCall) async => null,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.llfbandit.app_links/messages'),
        (methodCall) async => null,
      );

      await app.main();
      await tester.pumpAndSettle();

      expect(find.text('Track how you feel'), findsOneWidget);
      expect(find.text('Symptoms'), findsOneWidget);
    });
  });
}
