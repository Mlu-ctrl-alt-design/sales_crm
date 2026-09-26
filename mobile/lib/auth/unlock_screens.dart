import 'package:flutter/material.dart';

import '../theme/daystar_theme.dart';
import 'biometric_lock.dart';
import 'daystar_mark.dart';

/// Shown on open when biometric unlock is on and a session is stored.
/// Prompts straight away; the buttons are for a cancelled or failed prompt.
class UnlockScreen extends StatefulWidget {
  const UnlockScreen({
    super.key,
    required this.lock,
    required this.kind,
    required this.user,
    required this.onUnlocked,
    required this.onUsePassword,
  });

  final BiometricLock lock;
  final BiometricKind kind;
  final String user;
  final VoidCallback onUnlocked;
  final VoidCallback onUsePassword;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await widget.lock.unlock('Unlock Daystar Sales');
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final name = biometricName(widget.kind, Theme.of(context).platform);
    final icon = widget.kind == BiometricKind.fingerprint
        ? Icons.fingerprint
        : Icons.face_retouching_natural_outlined;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const DaystarMark(size: 64),
              const SizedBox(height: 24),
              Text('Welcome back', style: text.headlineSmall),
              const SizedBox(height: 6),
              Text(
                widget.user,
                style: text.bodyMedium?.copyWith(color: DaystarColors.muted),
              ),
              if (_failed) ...[
                const SizedBox(height: 16),
                Text(
                  "That didn't work. Try again or use your password.",
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: DaystarColors.moneyOut,
                  ),
                ),
              ],
              const Spacer(flex: 4),
              FilledButton.icon(
                key: const Key('unlock-biometric'),
                onPressed: _busy ? null : _unlock,
                icon: Icon(icon),
                label: Text('Unlock with $name'),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('unlock-password'),
                onPressed: widget.onUsePassword,
                child: const Text('Sign in with password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asked once, right after the first password sign-in on this device.
class OfferBiometricScreen extends StatefulWidget {
  const OfferBiometricScreen({
    super.key,
    required this.lock,
    required this.kind,
    required this.onDone,
  });

  final BiometricLock lock;
  final BiometricKind kind;

  /// Called with true if the user turned biometric unlock on.
  final ValueChanged<bool> onDone;

  @override
  State<OfferBiometricScreen> createState() => _OfferBiometricScreenState();
}

class _OfferBiometricScreenState extends State<OfferBiometricScreen> {
  bool _busy = false;

  Future<void> _enable() async {
    setState(() => _busy = true);
    // Prove it works on this phone before relying on it.
    final ok = await widget.lock.unlock('Turn on quick unlock');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) widget.onDone(true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final name = biometricName(widget.kind, Theme.of(context).platform);
    final icon = widget.kind == BiometricKind.fingerprint
        ? Icons.fingerprint
        : Icons.face_retouching_natural_outlined;
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
                child: Icon(icon, size: 32, color: DaystarColors.brand),
              ),
              const SizedBox(height: 24),
              Text(
                'Use $name next time?',
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Open the app with a glance instead of your password. '
                'You can still sign in with your password at any time.',
                style: text.bodyLarge?.copyWith(color: DaystarColors.muted),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 4),
              FilledButton(
                key: const Key('offer-enable'),
                onPressed: _busy ? null : _enable,
                child: Text('Use $name'),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('offer-skip'),
                onPressed: _busy ? null : () => widget.onDone(false),
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
