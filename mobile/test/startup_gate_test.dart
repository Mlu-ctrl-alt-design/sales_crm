import 'package:daystar_sales/app.dart';
import 'package:daystar_sales/auth/auth_repository.dart';
import 'package:daystar_sales/startup/app_status.dart';
import 'package:daystar_sales/startup/app_status_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

Future<void> pumpApp(
  WidgetTester tester,
  Future<AppStatus> Function() status, {
  String installedVersion = '1.0.0',
}) async {
  await tester.pumpWidget(
    DaystarApp(
      statusService: FakeStatusService(status),
      auth: FakeAuth(stored: const Session(user: 'mlu@example.com')),
      prefs: MemoryPrefs(),
      biometrics: FakeBiometrics(kind: null),
      installedVersion: installedVersion,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('maintenance mode shows only the maintenance message', (
    tester,
  ) async {
    await pumpApp(
      tester,
      () async => const AppStatus(
        enabled: true,
        maintenanceMode: true,
        maintenanceMessage: 'Back at 14:00',
      ),
    );

    expect(find.byKey(const Key('gate-maintenance')), findsOneWidget);
    expect(find.text('Back at 14:00'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets('maintenance Try again re-checks and opens once it is over', (
    tester,
  ) async {
    var maintenance = true;
    await pumpApp(
      tester,
      () async => AppStatus(enabled: true, maintenanceMode: maintenance),
    );
    expect(find.byKey(const Key('gate-maintenance')), findsOneWidget);

    maintenance = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('disabled config blocks the app', (tester) async {
    await pumpApp(
      tester,
      () async => const AppStatus(enabled: false, maintenanceMode: false),
    );
    expect(find.byKey(const Key('gate-disabled')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('outdated build is told to update', (tester) async {
    await pumpApp(
      tester,
      () async => const AppStatus(
        enabled: true,
        maintenanceMode: false,
        minimumAppVersion: '2.0.0',
      ),
    );
    expect(find.byKey(const Key('gate-update')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('unreachable server offers retry, not the app', (tester) async {
    await pumpApp(tester, () async => throw AppStatusException('offline'));
    expect(find.byKey(const Key('gate-error')), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('open config shows the three hero tabs', (tester) async {
    await pumpApp(
      tester,
      () async => const AppStatus(enabled: true, maintenanceMode: false),
    );
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Dashboard', 'Assistant', 'Quick send']) {
      expect(find.widgetWithText(NavigationDestination, label), findsOneWidget);
    }
  });

  testWidgets('+ opens quick create; New quote lands on Quick send', (
    tester,
  ) async {
    await pumpApp(
      tester,
      () async => const AppStatus(enabled: true, maintenanceMode: false),
    );

    await tester.tap(find.byKey(const Key('quick-create')));
    await tester.pumpAndSettle();
    expect(find.text('New invoice'), findsOneWidget);
    expect(find.text('New customer'), findsOneWidget);

    await tester.tap(find.byKey(const Key('create-quote')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Quick send'), findsOneWidget);
    // Already on the create flow, so the + button steps aside.
    expect(find.byKey(const Key('quick-create')), findsNothing);
  });
}
