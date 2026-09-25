import 'package:flutter/material.dart';

import 'app_status.dart';
import 'app_status_service.dart';

/// Checks Mobile Configuration before anything else renders.
///
/// Only [AppGate.open] shows [child]; every other gate replaces the whole
/// app with a single blocking screen.
class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.statusService,
    required this.installedVersion,
    required this.child,
  });

  final AppStatusService statusService;
  final String installedVersion;
  final Widget child;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late Future<AppStatus> _status = widget.statusService.fetch();

  void _retry() => setState(() => _status = widget.statusService.fetch());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppStatus>(
      future: _status,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return BlockingScreen(
            key: const Key('gate-error'),
            icon: Icons.cloud_off_outlined,
            title: "Can't reach Daystar",
            message: 'Check your connection and try again.',
            action: FilledButton(onPressed: _retry, child: const Text('Retry')),
          );
        }
        final status = snapshot.requireData;
        switch (status.evaluate(widget.installedVersion)) {
          case AppGate.open:
            return widget.child;
          case AppGate.disabled:
            return const BlockingScreen(
              key: Key('gate-disabled'),
              icon: Icons.block_outlined,
              title: 'App unavailable',
              message: 'The Daystar mobile app is currently switched off.',
            );
          case AppGate.maintenance:
            return BlockingScreen(
              key: const Key('gate-maintenance'),
              icon: Icons.construction_outlined,
              title: 'Down for maintenance',
              message: status.maintenanceMessage ??
                  "We're doing some maintenance. Please check back soon.",
            );
          case AppGate.updateRequired:
            return BlockingScreen(
              key: const Key('gate-update'),
              icon: Icons.system_update_outlined,
              title: 'Update required',
              message: 'Version ${status.minimumAppVersion} or later is '
                  'required. You have ${widget.installedVersion}.',
            );
        }
      },
    );
  }
}

class BlockingScreen extends StatelessWidget {
  const BlockingScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 24),
                Text(title,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                if (action != null) ...[const SizedBox(height: 24), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
