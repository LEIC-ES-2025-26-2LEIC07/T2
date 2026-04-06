import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinic_go/ui/favorites/views/favorites_view.dart';

void main() {
  group('FavoritesView', () {
    testWidgets('renders a search TextField', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FavoritesView())),
      );
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows "O que precisas?" hint text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FavoritesView())),
      );
      expect(find.text('O que precisas?'), findsOneWidget);
    });

    testWidgets('contains a search icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FavoritesView())),
      );
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('uses SafeArea wrapping', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FavoritesView())),
      );
      expect(find.byType(SafeArea), findsOneWidget);
    });
  });
}
