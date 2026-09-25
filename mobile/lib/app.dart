import 'package:flutter/material.dart';

import 'auth/auth_repository.dart';
import 'auth/login_screen.dart';
import 'shell/home_shell.dart';
import 'startup/app_status_service.dart';
import 'startup/startup_gate.dart';

class DaystarApp extends StatelessWidget {
  const DaystarApp({
    super.key,
    required this.statusService,
    required this.auth,
    required this.installedVersion,
  });

  final AppStatusService statusService;
  final AuthRepository auth;
  final String installedVersion;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daystar Sales',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1F4E79)),
      home: StartupGate(
        statusService: statusService,
        installedVersion: installedVersion,
        child: _AuthGate(auth: auth),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({required this.auth});

  final AuthRepository auth;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final Future<Session?> _restored = widget.auth.restore();
  Session? _session;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Session?>(
      future: _restored,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session = _session ?? snapshot.data;
        if (session == null) {
          return LoginScreen(
            auth: widget.auth,
            onSignedIn: (s) => setState(() => _session = s),
          );
        }
        return const HomeShell();
      },
    );
  }
}
