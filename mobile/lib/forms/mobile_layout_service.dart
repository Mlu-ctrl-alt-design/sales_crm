import 'dart:convert';

import 'package:http/http.dart' as http;

import 'mobile_layout.dart';

/// Reads a form layout from the server so ops can shape the phone's Add /
/// Edit forms from the Desk without a new mobile build.
///
/// Contract: `GET /api/method/daystar_mobile.api.mobile_layout.get` with
/// query params `doctype` and `mode`, `Authorization: Bearer <token>`.
/// The response body wraps our payload as `{"message": {...}}` (Frappe
/// convention for `@frappe.whitelist()` returns).
class MobileLayoutService {
  MobileLayoutService({
    required this.siteUrl,
    required Future<String?> Function() accessToken,
    http.Client? client,
  }) : _client = client ?? http.Client(),
       _accessToken = accessToken;

  final String siteUrl;
  final http.Client _client;
  final Future<String?> Function() _accessToken;

  static const _timeout = Duration(seconds: 15);

  Future<MobileLayout> fetch({
    required String doctype,
    required String mode,
  }) async {
    final token = await _accessToken();
    if (token == null || token.isEmpty) {
      throw MobileLayoutException('Not signed in.');
    }
    final uri = Uri.parse(
      '$siteUrl/api/method/daystar_mobile.api.mobile_layout.get',
    ).replace(queryParameters: {'doctype': doctype, 'mode': mode});

    final response = await _client
        .get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(_timeout);
    if (response.statusCode ~/ 100 != 2) {
      throw MobileLayoutException(
        'Layout request failed (${response.statusCode}).',
      );
    }
    final body = jsonDecode(response.body) as Map<String, Object?>;
    final payload = body['message'] as Map<String, Object?>?;
    if (payload == null) {
      throw MobileLayoutException('Malformed layout response.');
    }
    return MobileLayout.fromJson(payload);
  }
}

class MobileLayoutException implements Exception {
  MobileLayoutException(this.message);
  final String message;
  @override
  String toString() => 'MobileLayoutException: $message';
}
