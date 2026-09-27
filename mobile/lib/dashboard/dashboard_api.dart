import '../api/api_client.dart';
import 'models.dart';

/// `daystar_mobile.api.dashboard`.
abstract class DashboardApi {
  /// [refresh] skips the server's five-minute cache.
  Future<DashboardData> get(DashboardPeriod period, {bool refresh = false});
}

class HttpDashboardApi implements DashboardApi {
  HttpDashboardApi(this._client, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ApiClient _client;
  final DateTime Function() _now;

  @override
  Future<DashboardData> get(
    DashboardPeriod period, {
    bool refresh = false,
  }) async {
    final result = await _client.get('daystar_mobile.api.dashboard.get', {
      'period': period.key,
      if (refresh) 'refresh': '1',
    });
    return DashboardData.fromJson(result as Map<String, dynamic>, _now());
  }
}
