import 'package:flutter/material.dart';

import 'auth/auth_repository.dart';
import 'auth/biometric_lock.dart';
import 'auth/device_prefs.dart';
import 'auth/login_screen.dart';
import 'auth/unlock_screens.dart';
import 'shell/home_shell.dart';
import 'startup/app_status_service.dart';
import 'startup/startup_gate.dart';
import 'theme/daystar_theme.dart';

class DaystarApp extends StatelessWidget {
  const DaystarApp({
    super.key,
    required this.statusService,
    required this.auth,
    required this.prefs,
    required this.biometrics,
    required this.installedVersion,
  });

  final AppStatusService statusService;
  final AuthRepository auth;
  final DevicePrefs prefs;
  final BiometricLock biometrics;
  final String installedVersion;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daystar Sales',
      debugShowCheckedModeBanner: false,
      theme: DaystarTheme.light(),
      home: StartupGate(
        statusService: statusService,
        installedVersion: installedVersion,
        child: SignInFlow(auth: auth, prefs: prefs, biometrics: biometrics),
      ),
    );
  }
}

enum _Step { loading, signIn, unlock, offerBiometric, signedIn }

/// Password sign-in, optional Face ID / fingerprint unlock, then the app.
///
/// Biometric unlock gates the session already stored on the device; the
/// first sign-in on a phone always uses the password.
class SignInFlow extends StatefulWidget {
  const SignInFlow({
    super.key,
    required this.auth,
    required this.prefs,
    required this.biometrics,
    this.lockAfter = const Duration(minutes: 5),
    this.now = DateTime.now,
  });

  final AuthRepository auth;
  final DevicePrefs prefs;
  final BiometricLock biometrics;

  /// With quick unlock on, the app locks after this long in the background.
  final Duration lockAfter;
  final DateTime Function() now;

  @override
  State<SignInFlow> createState() => _SignInFlowState();
}

class _SignInFlowState extends State<SignInFlow> {
  _Step _step = _Step.loading;
  Session? _session;
  String? _lastEmail;
  BiometricKind? _kind;
  bool _unlockOn = false;

  /// Locked on top of the app, so work in progress survives the lock.
  bool _locked = false;
  DateTime? _backgroundedAt;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => _backgroundedAt ??= widget.now(),
      onShow: _returnedToForeground,
    );
    _start();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _returnedToForeground() {
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (since == null || _step != _Step.signedIn || _locked) return;
    if (!_unlockOn || _kind == null) return;
    if (widget.now().difference(since) >= widget.lockAfter) {
      setState(() => _locked = true);
    }
  }

  Future<void> _start() async {
    final results = await Future.wait([
      widget.auth.restore(),
      widget.prefs.lastEmail(),
      widget.prefs.biometricUnlock(),
      widget.biometrics.available(),
    ]);
    final session = results[0] as Session?;
    final unlockOn = results[2] as bool;
    _lastEmail = results[1] as String?;
    _kind = results[3] as BiometricKind?;
    _unlockOn = unlockOn;
    if (!mounted) return;
    setState(() {
      _session = session;
      _step = session == null
          ? _Step.signIn
          : (unlockOn && _kind != null ? _Step.unlock : _Step.signedIn);
    });
  }

  Future<void> _signedIn(Session session) async {
    await widget.prefs.setLastEmail(session.user);
    final offer =
        _kind != null &&
        !await widget.prefs.biometricOffered() &&
        !await widget.prefs.biometricUnlock();
    if (!mounted) return;
    setState(() {
      _session = session;
      _lastEmail = session.user;
      _step = offer ? _Step.offerBiometric : _Step.signedIn;
    });
  }

  Future<void> _offerDone(bool enabled) async {
    await widget.prefs.setBiometricUnlock(enabled);
    await widget.prefs.setBiometricOffered();
    _unlockOn = enabled;
    if (mounted) setState(() => _step = _Step.signedIn);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _Step.loading => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      _Step.signIn => LoginScreen(
        auth: widget.auth,
        initialEmail: _lastEmail,
        onSignedIn: _signedIn,
      ),
      _Step.unlock => UnlockScreen(
        lock: widget.biometrics,
        kind: _kind!,
        user: _session!.user,
        onUnlocked: () => setState(() => _step = _Step.signedIn),
        onUsePassword: () => setState(() => _step = _Step.signIn),
      ),
      _Step.offerBiometric => OfferBiometricScreen(
        lock: widget.biometrics,
        kind: _kind!,
        onDone: _offerDone,
      ),
      _Step.signedIn => Stack(
        children: [
          TickerMode(
            enabled: !_locked,
            child: ExcludeSemantics(
              excluding: _locked,
              child: const HomeShell(),
            ),
          ),
          if (_locked)
            UnlockScreen(
              key: const Key('lock-screen'),
              lock: widget.biometrics,
              kind: _kind!,
              user: _session!.user,
              onUnlocked: () => setState(() => _locked = false),
              onUsePassword: () => setState(() {
                _locked = false;
                _step = _Step.signIn;
              }),
            ),
        ],
      ),
    };
  }
}
