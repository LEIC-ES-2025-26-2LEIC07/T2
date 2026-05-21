import 'package:clinic_go/features/home/presentation/widgets/home_brutal_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('HomeBrutalButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpApp(
        HomeBrutalButton(
          label: 'Tomar agora',
          bg: Colors.black,
          fg: Colors.white,
          onPressed: () {},
        ),
      );
      expect(find.text('Tomar agora'), findsOneWidget);
    });

    testWidgets('isLoading: shows CircularProgressIndicator, hides label', (
      tester,
    ) async {
      await tester.pumpApp(
        HomeBrutalButton(
          label: 'Tomar agora',
          bg: Colors.black,
          fg: Colors.white,
          onPressed: () {},
          isLoading: true,
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Tomar agora'), findsNothing);
    });

    testWidgets('onPressed null: tapping does not invoke any callback', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpApp(
        HomeBrutalButton(
          label: 'Saltar',
          bg: Colors.white,
          fg: Colors.black,
          onPressed: null,
        ),
      );
      // Verify no exception is thrown and tapped remains false
      await tester.tap(find.byType(GestureDetector));
      expect(tapped, isFalse);
    });

    testWidgets('onPressed: tapping invokes callback once', (tester) async {
      var count = 0;
      await tester.pumpApp(
        HomeBrutalButton(
          label: 'Confirmar',
          bg: Colors.blue,
          fg: Colors.white,
          onPressed: () => count++,
        ),
      );
      await tester.tap(find.byType(GestureDetector));
      expect(count, 1);
    });
  });
}
