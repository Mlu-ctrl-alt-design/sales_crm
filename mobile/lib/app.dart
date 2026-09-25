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
  });

  final AuthRepository auth;
  final DevicePrefs prefs;
  final BiometricLock biometrics;

  @override
  State<SignInFlow> createState() => _SignInFlowState();
}

class _SignInFlowState extends State<SignInFlow> {
  _Step _step = _Step.loading;
  Session? _session;
  String? _lastEmail;
  BiometricKind? _kind;

  @override
  void initState() {
    super.initState();
    _start();
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
      _Step.signedIn => const HomeShell(),
    };
  }
}
