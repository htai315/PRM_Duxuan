  // This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:du_xuan/main.dart';
import 'package:du_xuan/di.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    final notificationService = buildNotificationService();
    await tester.pumpWidget(DuXuanApp(notificationService: notificationService));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
