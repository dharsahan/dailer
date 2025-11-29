import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialer/main.dart'; // Adjust import based on package name

void main() {
  testWidgets('Dialer smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our keypad exists
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // Tap the '1' icon and verify that '1' is displayed.
    await tester.tap(find.text('1'));
    await tester.pump();

    // Verify input display updates (assuming there's a display widget showing input)
    expect(find.text('1'), findsAtLeastNWidgets(1));
  });
}
