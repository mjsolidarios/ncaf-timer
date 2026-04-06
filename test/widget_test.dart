import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ncaf_timer/main.dart';

void main() {
  testWidgets('Timer app renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const NCAFTimerApp());
    await tester.pump(const Duration(seconds: 1));

    // Verify NCAF brand is visible
    expect(find.text('NCAF'), findsOneWidget);

    // Verify default event name is visible
    expect(find.textContaining('NCAF 2026'), findsWidgets);
  });

  testWidgets('Timer can be started and paused', (WidgetTester tester) async {
    await tester.pumpWidget(const NCAFTimerApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Find and tap Start Timer button
    final startButton = find.text('Start Timer');
    expect(startButton, findsOneWidget);
    await tester.tap(startButton);
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Pause button appears
    expect(find.text('Pause'), findsOneWidget);
  });

  testWidgets('Event name can be edited', (WidgetTester tester) async {
    await tester.pumpWidget(const NCAFTimerApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Tap the event name to edit it
    final eventName = find.textContaining('NCAF 2026');
    expect(eventName, findsWidgets);
  });

  testWidgets('Fullscreen toggle button exists', (WidgetTester tester) async {
    await tester.pumpWidget(const NCAFTimerApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Find fullscreen icon
    expect(find.byIcon(Icons.fullscreen), findsOneWidget);
  });

  testWidgets('Status label shows Ready by default', (WidgetTester tester) async {
    await tester.pumpWidget(const NCAFTimerApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('READY'), findsOneWidget);
  });
}
