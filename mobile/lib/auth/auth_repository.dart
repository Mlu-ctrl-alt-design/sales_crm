/// A signed-in user.
class Session {
  const Session({required this.user});
  final String user;
}

/// Token auth against Mobile Control's Mobile Refresh Token.
///
/// The concrete implementation is intentionally missing: Mobile Control's
/// login/refresh endpoints and payloads have not been inspected yet, and the
/// contract must come from its source, not be guessed.
abstract class AuthRepository {
  /// The stored session, if its tokens are still usable.
  Future<Session?> restore();

  Future<Session> login({required String username, required String password});

  Future<void> logout();
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Placeholder until the Mobile Control token contract is known.
class PendingMobileControlAuthRepository implements AuthRepository {
  @override
  Future<Session?> restore() async => null;

  @override
  Future<Session> login({required String username, required String password}) {
    throw AuthException(
      'Sign-in is not available yet: the Mobile Control token contract '
      'has not been wired up.',
    );
  }

  @override
  Future<void> logout() async {}
}
