import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:four_u_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smoke Test', () {
    testWidgets('Verify app starts and shows home screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('O que precisas?'), findsOneWidget);
    });
  });
}
