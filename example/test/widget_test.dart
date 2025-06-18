// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:metriqus_example/main.dart';

void main() {
  testWidgets('Metriqus Flutter SDK Example smoke test',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app has the correct title.
    expect(find.text('Metriqus Flutter SDK Demo'), findsOneWidget);

    // Verify that the status text appears.
    expect(find.text('Ready to test Metriqus Flutter SDK functions'),
        findsOneWidget);

    // Verify that some of the main sections are present.
    expect(find.text('🎯 Event Tracking Functions'), findsOneWidget);
    expect(find.text('👤 User Attribute Functions'), findsOneWidget);
  });
}
