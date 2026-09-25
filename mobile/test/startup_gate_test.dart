import 'package:daystar_sales/app.dart';
import 'package:daystar_sales/auth/auth_repository.dart';
import 'package:daystar_sales/startup/app_status.dart';
import 'package:daystar_sales/startup/app_status_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStatusService implements AppStatusService {
  _FakeStatusService(this.result);
  final Future<AppStatus> Function() result;

  @override
  Future<AppStatus> fetch() => result();
}

class _SignedInAuth implements AuthRepository {
  @override
  Future<Session?> restore() async => const Session(user: 'mlu@example.com');

  @override
  Future<Session> login({required String username, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {}
}

Future<void> pumpApp(
  WidgetTester tester,
  Future<AppStatus> Function() status, {
  String installedVersion = '1.0.0',
}) async {
  await tester.pumpWidget(DaystarApp(
    statusService: _FakeStatusService(status),
    auth: _SignedInAuth(),
    installedVersion: installedVersion,
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('maintenance mode shows only the maintenance message',
      (tester) async {
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
    expect(find.text('Retry'), findsOneWidget);
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
}
