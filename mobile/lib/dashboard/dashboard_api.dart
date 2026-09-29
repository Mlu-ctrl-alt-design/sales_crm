import 'dart:convert';

import '../api/api_client.dart';
import '../auth/key_value_store.dart';
import 'models.dart';

/// `daystar_mobile.api.dashboard`.
abstract class DashboardApi {
  /// [refresh] skips the server's five-minute cache.
  Future<DashboardData> get(DashboardPeriod period, {bool refresh = false});

  /// The last figures fetched for [period] on this device by the signed-in
  /// user, or null when there are none.
  Future<DashboardData?> cached(DashboardPeriod period);
}

class HttpDashboardApi implements DashboardApi {
  HttpDashboardApi(
    this._client, {
    required KeyValueStore store,
    required Future<String?> Function() currentUser,
    DateTime Function()? now,
  }) : _store = store,
       _currentUser = currentUser,
       _now = now ?? DateTime.now;

  final ApiClient _client;
  final KeyValueStore _store;

  /// Whose figures a cached copy may be shown to.
  final Future<String?> Function() _currentUser;
  final DateTime Function() _now;

  static String _key(DashboardPeriod period) => 'dashboard.${period.key}';

  @override
  Future<DashboardData> get(
    DashboardPeriod period, {
    bool refresh = false,
  }) async {
    final result = await _client.get('daystar_mobile.api.dashboard.get', {
      'period': period.key,
      if (refresh) 'refresh': '1',
    });
    if (result is! Map<String, dynamic>) {
      throw ApiException(
        "Daystar sent back figures the app couldn't read.",
        ApiErrorKind.server,
      );
    }
    final fetchedAt = _now();
    final data = DashboardData.fromJson(result, fetchedAt);
    final user = await _currentUser();
    if (user != null) {
      await _store.write(
        _key(period),
        jsonEncode({
          'user': user,
          'fetched_at': fetchedAt.toIso8601String(),
          'data': result,
        }),
      );
    }
    return data;
  }

  @override
  Future<DashboardData?> cached(DashboardPeriod period) async {
    final raw = await _store.read(_key(period));
    if (raw == null) return null;
    try {
      final saved = jsonDecode(raw) as Map<String, dynamic>;
      final user = await _currentUser();
      if (user == null || saved['user'] != user) return null;
      return DashboardData.fromJson(
        saved['data'] as Map<String, dynamic>,
        DateTime.parse(saved['fetched_at'] as String),
      );
    } catch (_) {
      // An unreadable copy is dropped; the next fetch replaces it.
      await _store.delete(_key(period));
      return null;
    }
  }
}
