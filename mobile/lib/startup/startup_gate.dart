import 'package:flutter/material.dart';

import '../theme/daystar_theme.dart';
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

  void _retry() {
    final status = widget.statusService.fetch();
    setState(() {
      _status = status;
    });
  }

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
            message: 'Check your signal or Wi-Fi, then try again.',
            actionLabel: 'Try again',
            onAction: _retry,
          );
        }
        final status = snapshot.requireData;
        switch (status.evaluate(widget.installedVersion)) {
          case AppGate.open:
            return widget.child;
          case AppGate.disabled:
            return const BlockingScreen(
              key: Key('gate-disabled'),
              icon: Icons.lock_clock_outlined,
              title: 'The app is switched off',
              message:
                  'Daystar Sales is not available right now. '
                  'Ask Mlu if you need access.',
            );
          case AppGate.maintenance:
            return BlockingScreen(
              key: const Key('gate-maintenance'),
              icon: Icons.construction_outlined,
              title: 'Down for maintenance',
              message:
                  status.maintenanceMessage ??
                  "We're making some changes. Check back soon.",
              actionLabel: 'Try again',
              onAction: _retry,
            );
          case AppGate.updateRequired:
            return BlockingScreen(
              key: const Key('gate-update'),
              icon: Icons.system_update_outlined,
              title: 'Update required',
              message:
                  'This version (${widget.installedVersion}) is no '
                  'longer supported. Update to '
                  '${status.minimumAppVersion} or later to continue.',
            );
        }
      },
    );
  }
}

/// Icon, heading, one sentence, at most one button. Used for every state
/// that takes over the whole app.
class BlockingScreen extends StatelessWidget {
  const BlockingScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: DaystarColors.brandSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 30, color: DaystarColors.brand),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: text.bodyLarge?.copyWith(color: DaystarColors.muted),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 4),
              if (actionLabel != null)
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
        ),
      ),
    );
  }
}
