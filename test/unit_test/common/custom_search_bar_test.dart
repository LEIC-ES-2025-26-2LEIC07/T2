import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinic_go/ui/common/widgets/custom_search_bar.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(home: Scaffold(body: w));

  group('CustomSearchBar', () {
    testWidgets('renders with default hint text', (tester) async {
      await tester.pumpWidget(wrap(const CustomSearchBar()));
      expect(find.text('O que precisas?'), findsOneWidget);
    });

    testWidgets('renders with custom hint text', (tester) async {
      await tester.pumpWidget(
        wrap(const CustomSearchBar(hintText: 'Pesquisar...')),
      );
      expect(find.text('Pesquisar...'), findsOneWidget);
    });

    testWidgets('shows search icon', (tester) async {
      await tester.pumpWidget(wrap(const CustomSearchBar()));
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('fires onChanged callback when text is entered', (
      tester,
    ) async {
      String? captured;
      await tester.pumpWidget(
        wrap(CustomSearchBar(onChanged: (v) => captured = v)),
      );

      await tester.enterText(find.byType(TextField), 'yoga');
      expect(captured, 'yoga');
    });

    testWidgets('works with null onChanged (no crash)', (tester) async {
      await tester.pumpWidget(wrap(const CustomSearchBar()));
      await tester.enterText(find.byType(TextField), 'test');
      // No exception = pass.
    });
  });
}
