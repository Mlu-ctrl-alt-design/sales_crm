import 'dart:convert';

import 'package:http/http.dart' as http;

/// Inserts a new document via Frappe's generic `frappe.client.insert`.
///
/// Kept generic so we don't need a matching endpoint per doctype — the
/// server's Mobile Field Layout decides *what* to send, this decides *how*.
class FormSubmitService {
  FormSubmitService({
    required this.siteUrl,
    required Future<String?> Function() accessToken,
    http.Client? client,
  }) : _client = client ?? http.Client(),
       _accessToken = accessToken;

  final String siteUrl;
  final http.Client _client;
  final Future<String?> Function() _accessToken;

  static const _timeout = Duration(seconds: 20);

  /// POST to `frappe.client.insert`; returns the created doc name.
  Future<String> insert({
    required String doctype,
    required Map<String, Object?> values,
  }) async {
    final token = await _accessToken();
    if (token == null || token.isEmpty) {
      throw FormSubmitException('Not signed in.');
    }
    final uri = Uri.parse('$siteUrl/api/method/frappe.client.insert');
    final body = <String, Object?>{
      'doc': {'doctype': doctype, ...values},
    };
    final response = await _client
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    if (response.statusCode ~/ 100 != 2) {
      throw FormSubmitException(_messageFrom(response) ?? 'Save failed');
    }
    final decoded = jsonDecode(response.body) as Map<String, Object?>;
    final message = decoded['message'];
    if (message is Map<String, Object?>) {
      return message['name'] as String? ?? '';
    }
    return '';
  }

  String? _messageFrom(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, Object?>;
      // Frappe surfaces user-facing messages either in `_server_messages`
      // (a JSON-encoded list of JSON strings) or in `exc`.
      final raw = body['_server_messages'] as String?;
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        if (list.isNotEmpty) {
          final first = jsonDecode(list.first as String) as Map;
          return first['message'] as String?;
        }
      }
      return body['exception'] as String?;
    } catch (_) {
      return null;
    }
  }
}

class FormSubmitException implements Exception {
  FormSubmitException(this.message);
  final String message;
  @override
  String toString() => 'FormSubmitException: $message';
}
