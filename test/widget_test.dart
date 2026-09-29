import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:nova/main.dart';
import 'package:nova/services/firebase_auth_service.dart';

class _InvalidCredentialAuthService extends FirebaseAuthService {
  _InvalidCredentialAuthService(this.onSignIn);

  final VoidCallback onSignIn;

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    onSignIn();
    throw FirebaseAuthException(code: 'invalid-credential');
  }
}

void main() {
  testWidgets('Nova app loads auth UI by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NovaApp(),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to Nova'), findsOneWidget);
  });

  testWidgets('password visibility can be toggled on auth forms',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NovaApp(),
      ),
    );

    var passwordField = find.descendant(
      of: find.byType(TextFormField).at(1),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(passwordField).obscureText, isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump(const Duration(milliseconds: 100));

    passwordField = find.descendant(
      of: find.byType(TextFormField).at(1),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(passwordField).obscureText, isFalse);

    await tester.tap(find.text('Create a new account'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byTooltip('Show confirm password'), findsOneWidget);

    var confirmPasswordField = find.descendant(
      of: find.byType(TextFormField).at(3),
      matching: find.byType(EditableText),
    );
    expect(
        tester.widget<EditableText>(confirmPasswordField).obscureText, isTrue);

    await tester.tap(find.byTooltip('Show confirm password'));
    await tester.pump(const Duration(milliseconds: 100));

    confirmPasswordField = find.descendant(
      of: find.byType(TextFormField).at(3),
      matching: find.byType(EditableText),
    );
    expect(
        tester.widget<EditableText>(confirmPasswordField).obscureText, isFalse);
  });

  testWidgets('shows a message when sign in credentials are incorrect',
      (WidgetTester tester) async {
    var signInCalled = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthServiceProvider.overrideWith(
            (ref) => _InvalidCredentialAuthService(() => signInCalled = true),
          ),
        ],
        child: const NovaApp(),
      ),
    );

    await tester.enterText(
        find.byType(TextFormField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'incorrect');
    final signInButton = find.widgetWithText(FilledButton, 'Sign in');
    await tester.ensureVisible(signInButton);
    await tester.tap(signInButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(signInCalled, isTrue);
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
  });
}
