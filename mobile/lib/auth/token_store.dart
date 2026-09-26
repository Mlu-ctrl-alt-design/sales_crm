import 'dart:convert';
import 'dart:math';

import 'key_value_store.dart';

/// Tokens from Mobile Control plus who they belong to.
class StoredTokens {
  const StoredTokens({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.issuedAt,
    this.fullName,
  });

  final String user;
  final String? fullName;
  final String accessToken;
  final String refreshToken;

  /// When [accessToken] was issued. Mobile Control's access tokens are
  /// encrypted, so the app can't read their expiry and tracks it here.
  final DateTime issuedAt;

  Map<String, Object?> toJson() => {
    'user': user,
    'full_name': fullName,
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'issued_at': issuedAt.toUtc().toIso8601String(),
  };

  static StoredTokens? fromJson(Map<String, dynamic> json) {
    final user = json['user'], access = json['access_token'];
    final refresh = json['refresh_token'], issued = json['issued_at'];
    if (user is! String || access is! String || refresh is! String) {
      return null;
    }
    return StoredTokens(
      user: user,
      fullName: json['full_name'] as String?,
      accessToken: access,
      refreshToken: refresh,
      issuedAt:
          DateTime.tryParse(issued is String ? issued : '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Keeps the session tokens and this install's device id in secure storage.
class TokenStore {
  TokenStore(this._store);

  final KeyValueStore _store;

  static const _tokensKey = 'mobile_control_tokens';
  static const _deviceKey = 'device_id';

  Future<StoredTokens?> load() async {
    final raw = await _store.read(_tokensKey);
    if (raw == null) return null;
    try {
      return StoredTokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  Future<void> save(StoredTokens tokens) =>
      _store.write(_tokensKey, jsonEncode(tokens.toJson()));

  Future<void> clear() => _store.delete(_tokensKey);

  /// A random id for this install, sent at sign-in so Mobile Control can
  /// tell a user's devices apart. Created on first use.
  Future<String> deviceId() async {
    final existing = await _store.read(_deviceKey);
    if (existing != null) return existing;
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _store.write(_deviceKey, id);
    return id;
  }
}
