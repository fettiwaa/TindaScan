import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/features/auth/presentation/login_screen.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late MockAuthRepository auth;

  setUp(() => auth = MockAuthRepository());

  Future<void> pump(WidgetTester tester, {double textScale = 1}) =>
      tester.pumpApp(
        const LoginScreen(),
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        textScale: textScale,
      );

  testWidgets('validates empty fields without calling the backend', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text('This field is required.'), findsNWidgets(2));
    verifyNever(
      () => auth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('shows a friendly error on wrong credentials', (tester) async {
    when(
      () => auth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AuthFailure(AuthFailureReason.invalidCredentials));
    await pump(tester);

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'nena@store.ph',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('login-password')),
        matching: find.byType(TextField),
      ),
      'wrong-password',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Wrong email or password.'), findsOneWidget);
    verify(
      () => auth.signIn(email: 'nena@store.ph', password: 'wrong-password'),
    ).called(1);
  });

  testWidgets('password visibility toggle has a semantic label', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byTooltip('Show password'), findsOneWidget);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('renders without overflow at 1.5x text scale', (tester) async {
    await pump(tester, textScale: 1.5);
    expect(tester.takeException(), isNull);
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('is translated to Filipino', (tester) async {
    await tester.pumpApp(
      const LoginScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      locale: const Locale('fil'),
    );
    expect(find.text('Mag-sign in'), findsOneWidget);
  });
}
