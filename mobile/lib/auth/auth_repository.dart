/// A signed-in user.
class Session {
  const Session({required this.user, this.fullName});

  /// The Frappe user id (usually the email).
  final String user;
  final String? fullName;
}

/// Sign-in against the Daystar site.
abstract class AuthRepository {
  /// The session stored on this device, if it can still be used.
  Future<Session?> restore();

  Future<Session> login({required String username, required String password});

  Future<void> logout();
}

/// A sign-in problem the user can act on; [message] is shown as-is.
class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
