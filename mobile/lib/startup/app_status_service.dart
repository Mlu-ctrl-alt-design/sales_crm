import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_status.dart';

abstract class AppStatusService {
  Future<AppStatus> fetch();
}

/// Reads [AppStatus] from `daystar_mobile.api.app.get_app_status`.
///
/// The endpoint is guest-accessible so the gate runs before login.
class HttpAppStatusService implements AppStatusService {
  HttpAppStatusService({required this.siteUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String siteUrl;
  final http.Client _client;

  @override
  Future<AppStatus> fetch() async {
    final uri = Uri.parse(
      '$siteUrl/api/method/daystar_mobile.api.app.get_app_status',
    );
    final response = await _client
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw AppStatusException('Server responded ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AppStatus.fromJson(body['message'] as Map<String, dynamic>);
  }
}

class AppStatusException implements Exception {
  AppStatusException(this.message);
  final String message;

  @override
  String toString() => message;
}
