import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:four_u_app/main.dart';

void main() {
  testWidgets('renders a blank home scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(const FourUApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(SafeArea), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
  });
}
