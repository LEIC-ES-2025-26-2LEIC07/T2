import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Extension to streamline pumping the main app or a wrapped widget in tests.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget widget) {
    return pumpWidget(
      MaterialApp(
        home: widget,
        theme: ThemeData(
          useMaterial3: true,
          splashFactory: NoSplash.splashFactory,
        ),
      ),
    );
  }
}
