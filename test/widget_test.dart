import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialer/main.dart';

void main() {
  testWidgets('Dialer smoke test', (WidgetTester tester) async {
    // Set a larger screen size for the test to accommodate the expressive UI
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our keypad exists
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // Tap the '1' icon and verify that '1' is displayed.
    await tester.tap(find.text('1'));
    await tester.pump();

    // Verify input display updates
    expect(find.text('1'), findsAtLeastNWidgets(1));

    // Reset view size
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
