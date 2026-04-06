import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinic_go/ui/common/widgets/floating_bottom_nav_bar.dart';

void main() {
  Widget wrapInStack({
    required int currentIndex,
    required Function(int) onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            FloatingBottomNavBar(currentIndex: currentIndex, onTap: onTap),
          ],
        ),
      ),
    );
  }

  group('FloatingBottomNavBar', () {
    testWidgets('renders 5 icon buttons', (tester) async {
      await tester.pumpWidget(wrapInStack(currentIndex: 2, onTap: (_) {}));
      expect(find.byType(IconButton).evaluate().length, 5);
    });

    testWidgets('calls onTap with correct index when an icon is tapped', (
      tester,
    ) async {
      int? tapped;
      await tester.pumpWidget(
        wrapInStack(currentIndex: 2, onTap: (i) => tapped = i),
      );

      // Tap the home icon (index 2)
      await tester.tap(find.byIcon(Icons.home_outlined));
      expect(tapped, 2);
    });

    testWidgets('active icon is black, inactive icons are grey', (
      tester,
    ) async {
      await tester.pumpWidget(wrapInStack(currentIndex: 0, onTap: (_) {}));

      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      // Index 0 should be black
      expect(icons[0].color, Colors.black);
      // Others should NOT be black
      for (var i = 1; i < icons.length; i++) {
        expect(icons[i].color, isNot(Colors.black));
      }
    });

    testWidgets('renders all expected icons', (tester) async {
      await tester.pumpWidget(wrapInStack(currentIndex: 0, onTap: (_) {}));

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('can tap each navigation item', (tester) async {
      final tapped = <int>[];
      await tester.pumpWidget(wrapInStack(currentIndex: 0, onTap: tapped.add));

      final icons = [
        Icons.person_outline,
        Icons.favorite_border,
        Icons.home_outlined,
        Icons.calendar_today_outlined,
        Icons.settings_outlined,
      ];

      for (var i = 0; i < icons.length; i++) {
        await tester.tap(find.byIcon(icons[i]));
      }
      expect(tapped, [0, 1, 2, 3, 4]);
    });
  });
}
