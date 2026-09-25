import 'package:daystar_sales/auth/auth_repository.dart';
import 'package:daystar_sales/auth/biometric_lock.dart';
import 'package:daystar_sales/auth/device_prefs.dart';
import 'package:daystar_sales/startup/app_status.dart';
import 'package:daystar_sales/startup/app_status_service.dart';

class FakeStatusService implements AppStatusService {
  FakeStatusService(this.result);
  final Future<AppStatus> Function() result;

  @override
  Future<AppStatus> fetch() => result();
}

class FakeAuth implements AuthRepository {
  FakeAuth({this.stored});

  Session? stored;
  int logins = 0;

  @override
  Future<Session?> restore() async => stored;

  @override
  Future<Session> login({
    required String username,
    required String password,
  }) async {
    logins++;
    return stored = Session(user: username);
  }

  @override
  Future<void> logout() async => stored = null;
}

class MemoryPrefs implements DevicePrefs {
  String? email;
  bool unlock = false;
  bool offered = false;

  @override
  Future<String?> lastEmail() async => email;
  @override
  Future<void> setLastEmail(String value) async => email = value;
  @override
  Future<bool> biometricUnlock() async => unlock;
  @override
  Future<void> setBiometricUnlock(bool enabled) async => unlock = enabled;
  @override
  Future<bool> biometricOffered() async => offered;
  @override
  Future<void> setBiometricOffered() async => offered = true;
}

class FakeBiometrics implements BiometricLock {
  FakeBiometrics({this.kind = BiometricKind.face, this.succeeds = true});

  BiometricKind? kind;
  bool succeeds;
  int prompts = 0;

  @override
  Future<BiometricKind?> available() async => kind;

  @override
  Future<bool> unlock(String reason) async {
    prompts++;
    return succeeds;
  }
}

const openStatus = AppStatus(enabled: true, maintenanceMode: false);
