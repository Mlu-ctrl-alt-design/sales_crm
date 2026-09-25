import 'package:daystar_sales/app.dart';
import 'package:daystar_sales/auth/auth_repository.dart';
import 'package:daystar_sales/auth/biometric_lock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

Future<void> pumpFlow(
  WidgetTester tester, {
  required FakeAuth auth,
  required MemoryPrefs prefs,
  required FakeBiometrics bio,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SignInFlow(auth: auth, prefs: prefs, biometrics: bio),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> signIn(WidgetTester tester, String email) async {
  await tester.enterText(find.byKey(const Key('login-email')), email);
  await tester.enterText(find.byKey(const Key('login-password')), 'secret');
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
}

final iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

void main() {
  testWidgets('first sign-in offers Face ID once, and turning it on works', (
    tester,
  ) async {
    final prefs = MemoryPrefs();
    final bio = FakeBiometrics();
    await pumpFlow(tester, auth: FakeAuth(), prefs: prefs, bio: bio);

    await signIn(tester, 'mlu@example.com');
    expect(find.text('Use Face ID next time?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('offer-enable')));
    await tester.pumpAndSettle();

    expect(bio.prompts, 1, reason: 'proves it works before relying on it');
    expect(prefs.unlock, isTrue);
    expect(prefs.offered, isTrue);
    expect(prefs.email, 'mlu@example.com');
    expect(find.byType(NavigationBar), findsOneWidget);
  }, variant: iOS);

  testWidgets('Not now skips it and is not asked again', (tester) async {
    final prefs = MemoryPrefs();
    await pumpFlow(
      tester,
      auth: FakeAuth(),
      prefs: prefs,
      bio: FakeBiometrics(),
    );

    await signIn(tester, 'mlu@example.com');
    await tester.tap(find.byKey(const Key('offer-skip')));
    await tester.pumpAndSettle();

    expect(prefs.unlock, isFalse);
    expect(prefs.offered, isTrue);
    expect(find.byType(NavigationBar), findsOneWidget);
  }, variant: iOS);

  testWidgets('a failed Face ID check does not turn it on', (tester) async {
    final prefs = MemoryPrefs();
    await pumpFlow(
      tester,
      auth: FakeAuth(),
      prefs: prefs,
      bio: FakeBiometrics(succeeds: false),
    );

    await signIn(tester, 'mlu@example.com');
    await tester.tap(find.byKey(const Key('offer-enable')));
    await tester.pumpAndSettle();

    expect(prefs.unlock, isFalse);
    expect(find.text('Use Face ID next time?'), findsOneWidget);
  }, variant: iOS);

  testWidgets('with Face ID on, opening the app prompts and then unlocks', (
    tester,
  ) async {
    final prefs = MemoryPrefs()
      ..unlock = true
      ..offered = true;
    final bio = FakeBiometrics();
    await pumpFlow(
      tester,
      auth: FakeAuth(stored: const Session(user: 'mlu@example.com')),
      prefs: prefs,
      bio: bio,
    );

    expect(bio.prompts, 1, reason: 'prompts straight away');
    expect(find.byType(NavigationBar), findsOneWidget);
  }, variant: iOS);

  testWidgets('cancelled Face ID stays locked and offers the password', (
    tester,
  ) async {
    final prefs = MemoryPrefs()
      ..unlock = true
      ..offered = true
      ..email = 'mlu@example.com';
    final auth = FakeAuth(stored: const Session(user: 'mlu@example.com'));
    await pumpFlow(
      tester,
      auth: auth,
      prefs: prefs,
      bio: FakeBiometrics(succeeds: false),
    );

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Unlock with Face ID'), findsOneWidget);

    await tester.tap(find.byKey(const Key('unlock-password')));
    await tester.pumpAndSettle();
    // Remembered email is prefilled.
    expect(find.text('mlu@example.com'), findsOneWidget);

    await signIn(tester, 'mlu@example.com');
    expect(auth.logins, 1);
    expect(find.byType(NavigationBar), findsOneWidget);
  }, variant: iOS);

  testWidgets('no enrolled biometrics: plain password sign-in, no offer', (
    tester,
  ) async {
    final prefs = MemoryPrefs();
    await pumpFlow(
      tester,
      auth: FakeAuth(),
      prefs: prefs,
      bio: FakeBiometrics(kind: null),
    );

    await signIn(tester, 'rep@example.com');
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(prefs.offered, isFalse);
  }, variant: iOS);

  test('uses the phone\'s own name for it', () {
    expect(biometricName(BiometricKind.face, TargetPlatform.iOS), 'Face ID');
    expect(
      biometricName(BiometricKind.fingerprint, TargetPlatform.iOS),
      'Touch ID',
    );
    expect(
      biometricName(BiometricKind.fingerprint, TargetPlatform.android),
      'fingerprint',
    );
  });
}
