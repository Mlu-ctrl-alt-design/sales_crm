import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_repository.dart';
import 'token_store.dart';

/// Token sign-in against Mobile Control (frappe-mobile-control, `develop`).
///
/// Contract, from `mobile_control/api/api_auth.py`:
/// - `POST /api/method/mobile_auth.login` with `username`, `password` and
///   `device_id`. Tokens come back at the top level of the response:
///   `access_token` (24 h), `refresh_token` (30 days), `user`, `full_name`.
///   The user needs Mobile Control's "Mobile User" role.
/// - `POST /api/method/mobile_auth.refresh_token` with `refresh_token`
///   returns a new pair; the old refresh token is revoked. 401 means the
///   refresh token is no longer valid.
/// - Authenticated calls send `Authorization: Bearer <access_token>`.
/// - `POST /api/method/mobile_auth.logout` revokes every refresh token the
///   user has, on all their devices.
class MobileControlAuthRepository implements AuthRepository {
  MobileControlAuthRepository({
    required this.siteUrl,
    required TokenStore tokens,
    http.Client? client,
    DateTime Function()? now,
  }) : _tokens = tokens,
       _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  final String siteUrl;
  final TokenStore _tokens;
  final http.Client _client;
  final DateTime Function() _now;

  /// Mobile Control issues 24-hour access tokens; refresh an hour early.
  static const refreshAfter = Duration(hours: 23);
  static const _timeout = Duration(seconds: 20);

  Future<StoredTokens?>? _refreshing;

  @override
  Future<Session> login({
    required String username,
    required String password,
  }) async {
    final response = await _post('mobile_auth.login', {
      'username': username,
      'password': password,
      'device_id': await _tokens.deviceId(),
    });
    final body = _decode(response);
    if (response.statusCode != 200) throw _loginError(response, body);
    final stored = _storedFrom(body);
    if (stored == null) {
      throw AuthException("Sign-in didn't complete. Try again.");
    }
    await _tokens.save(stored);
    return Session(user: stored.user, fullName: stored.fullName);
  }

  @override
  Future<Session?> restore() async {
    var stored = await _tokens.load();
    if (stored == null) return null;
    if (_isStale(stored)) {
      try {
        stored = await _refresh(stored);
      } on AuthException {
        return null; // Refresh token revoked or expired: sign in again.
      } on Object {
        // Offline: keep the session; the next call will refresh.
      }
      if (stored == null) return null;
    }
    return Session(user: stored.user, fullName: stored.fullName);
  }

  /// A usable access token for `Authorization: Bearer`, refreshed if old.
  /// Null when signed out or the session can no longer be refreshed.
  Future<String?> accessToken() async {
    final stored = await _tokens.load();
    if (stored == null) return null;
    if (!_isStale(stored)) return stored.accessToken;
    try {
      return (await _refresh(stored))?.accessToken;
    } on AuthException {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    final stored = await _tokens.load();
    await _tokens.clear();
    if (stored == null) return;
    try {
      await _client
          .post(
            _uri('mobile_auth.logout'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${stored.accessToken}',
            },
          )
          .timeout(_timeout);
    } on Object {
      // Signed out on this phone either way; the server copy expires.
    }
  }

  bool _isStale(StoredTokens t) =>
      _now().difference(t.issuedAt) >= refreshAfter;

  /// One refresh at a time: Mobile Control revokes the old refresh token,
  /// so two parallel refreshes would sign the user out.
  Future<StoredTokens?> _refresh(StoredTokens current) {
    return _refreshing ??= _doRefresh(
      current,
    ).whenComplete(() => _refreshing = null);
  }

  Future<StoredTokens?> _doRefresh(StoredTokens current) async {
    final response = await _post('mobile_auth.refresh_token', {
      'refresh_token': current.refreshToken,
    });
    if (response.statusCode == 401 || response.statusCode == 403) {
      await _tokens.clear();
      throw AuthException('Your session has ended. Sign in again.');
    }
    if (response.statusCode != 200) {
      throw http.ClientException('Refresh failed: ${response.statusCode}');
    }
    final stored = _storedFrom(_decode(response));
    if (stored == null) {
      throw http.ClientException('Refresh response had no tokens');
    }
    await _tokens.save(stored);
    return stored;
  }

  Future<http.Response> _post(String method, Map<String, String> body) {
    return _client
        .post(
          _uri(method),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  Uri _uri(String method) => Uri.parse('$siteUrl/api/method/$method');

  StoredTokens? _storedFrom(Map<String, dynamic> body) {
    final user = body['user'], access = body['access_token'];
    final refresh = body['refresh_token'];
    if (user is! String || access is! String || refresh is! String) {
      return null;
    }
    return StoredTokens(
      user: user,
      fullName: body['full_name'] as String?,
      accessToken: access,
      refreshToken: refresh,
      issuedAt: _now(),
    );
  }

  static Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }

  /// Turns Mobile Control's errors into something the user can act on.
  static AuthException _loginError(
    http.Response response,
    Map<String, dynamic> body,
  ) {
    final text = '${body['message'] ?? ''} ${body['_server_messages'] ?? ''}'
        .toLowerCase();
    if (response.statusCode == 429) {
      return AuthException(
        'Too many sign-in attempts. Wait a few minutes and try again.',
      );
    }
    if (text.contains('not allowed to use mobile app')) {
      return AuthException(
        "Your account isn't set up for the mobile app yet. Ask Mlu to give "
        'you the Mobile User role.',
      );
    }
    if (text.contains('invalid login') || text.contains('incorrect password')) {
      return AuthException("That email and password don't match.");
    }
    if (text.contains('disabled')) {
      return AuthException('This account is disabled. Ask Mlu to turn it on.');
    }
    return AuthException("Couldn't sign in. Try again in a moment.");
  }
}
