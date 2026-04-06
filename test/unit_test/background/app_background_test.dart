import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinic_go/ui/background/view_models/app_background.dart';

void main() {
  group('AppBackground', () {
    testWidgets('renders its child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppBackground(child: Text('Hello Background'))),
      );
      expect(find.text('Hello Background'), findsOneWidget);
    });

    testWidgets('uses a Container as the root to fill available space', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppBackground(child: SizedBox())),
      );
      expect(find.byType(Container), findsWidgets);
      // AppBackground renders exactly one CustomPaint as a direct child of its
      // Container; use a descendant finder to avoid matching framework-internal
      // CustomPaints (e.g. those used by MaterialApp's overlay).
      expect(
        find.descendant(
          of: find.byType(AppBackground),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('can wrap multiple children via a Column', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppBackground(child: Column(children: [Text('A'), Text('B')])),
        ),
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });

  group('TopographicPainter', () {
    test('shouldRepaint returns false', () {
      final painter = TopographicPainter();
      expect(painter.shouldRepaint(TopographicPainter()), isFalse);
    });
  });
}
