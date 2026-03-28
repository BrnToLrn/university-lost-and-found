import 'package:flutter_test/flutter_test.dart';

import 'package:prefinalexam/screens/login_page.dart';

import 'package:flutter/material.dart';

void main() {
  testWidgets('Login page renders sign-in UI', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
