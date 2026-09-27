import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Calls whitelisted Frappe methods as the signed-in user.
///
/// Mobile Control's `before_request` hook turns the bearer access token
/// into Frappe token auth for every request, so `daystar_mobile` endpoints
/// run as `frappe.session.user`.
class ApiClient {
  ApiClient({
    required this.siteUrl,
    required this.accessToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String siteUrl;

  /// A usable access token, or null when signed out.
  final Future<String?> Function() accessToken;
  final http.Client _client;

  static const _timeout = Duration(seconds: 30);

  /// `GET /api/method/<method>`; returns Frappe's `message`.
  Future<Object?> get(String method, [Map<String, String>? query]) async {
    final response = await _send(
      (headers) => _client.get(_uri(method, query), headers: headers),
    );
    return _message(response);
  }

  /// `POST /api/method/<method>` with a JSON body; returns `message`.
  Future<Object?> post(String method, Map<String, Object?> body) async {
    final response = await _send(
      (headers) => _client.post(
        _uri(method),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    return _message(response);
  }

  /// A file-returning method (e.g. a PDF), as raw bytes.
  Future<Uint8List> download(String method, Map<String, String> query) async {
    final response = await _send(
      (headers) => _client.get(_uri(method, query), headers: headers),
    );
    return response.bodyBytes;
  }

  Uri _uri(String method, [Map<String, String>? query]) =>
      Uri.parse('$siteUrl/api/method/$method').replace(queryParameters: query);

  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    final token = await accessToken();
    if (token == null) {
      throw ApiException(
        'Your session has ended. Sign in again.',
        ApiErrorKind.signedOut,
      );
    }
    final http.Response response;
    try {
      response = await request({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      }).timeout(_timeout);
    } on TimeoutException {
      throw ApiException(
        'Daystar took too long to answer. Check your signal and try again.',
        ApiErrorKind.offline,
      );
    } on SocketException {
      throw ApiException(
        "Couldn't reach Daystar. Check your signal and try again.",
        ApiErrorKind.offline,
      );
    } on http.ClientException {
      throw ApiException(
        "Couldn't reach Daystar. Check your signal and try again.",
        ApiErrorKind.offline,
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    throw errorFrom(response);
  }

  static Object? _message(http.Response response) {
    final decoded = _decode(response.body);
    return decoded is Map<String, dynamic> ? decoded['message'] : null;
  }

  /// Frappe's error response as one sentence the user can act on.
  static ApiException errorFrom(http.Response response) {
    final body = _decode(response.body);
    final map = body is Map<String, dynamic> ? body : const <String, dynamic>{};
    final excType = '${map['exc_type'] ?? ''}';
    final message = _serverMessage(map) ?? _exceptionText(map);

    if (response.statusCode == 401 || excType == 'AuthenticationError') {
      return ApiException(
        'Your session has ended. Sign in again.',
        ApiErrorKind.signedOut,
      );
    }
    if (response.statusCode == 403 || excType == 'PermissionError') {
      return ApiException(
        message ?? "You don't have access to do that.",
        ApiErrorKind.notPermitted,
      );
    }
    if (response.statusCode >= 500) {
      return ApiException(
        'Something went wrong on Daystar. Try again in a moment.',
        ApiErrorKind.server,
      );
    }
    return ApiException(
      message ?? "Daystar couldn't do that. Try again.",
      ApiErrorKind.rejected,
    );
  }

  /// The last message in `_server_messages` (a JSON list of JSON strings).
  static String? _serverMessage(Map<String, dynamic> body) {
    final raw = body['_server_messages'];
    if (raw is! String) return null;
    final list = _decode(raw);
    if (list is! List) return null;
    for (final entry in list.reversed) {
      final decoded = entry is String ? _decode(entry) : entry;
      final text = decoded is Map ? decoded['message'] : decoded;
      if (text is String && _plain(text).isNotEmpty) return _plain(text);
    }
    return null;
  }

  /// `frappe.exceptions.ValidationError: Row 1: ...` → `Row 1: ...`
  static String? _exceptionText(Map<String, dynamic> body) {
    final raw = body['exception'];
    if (raw is! String || raw.isEmpty) return null;
    final colon = raw.indexOf(': ');
    final text = _plain(colon == -1 ? raw : raw.substring(colon + 2));
    return text.isEmpty ? null : text;
  }

  static String _plain(String html) => html
      .replaceAll(RegExp(r'<br\s*/?>'), ' ')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static Object? _decode(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }
}

enum ApiErrorKind {
  /// No answer: the request may or may not have reached the server.
  offline,
  signedOut,
  notPermitted,

  /// The server refused it (validation, price lock, bad input).
  rejected,
  server,
}

/// A failed call; [message] is shown to the user as-is.
class ApiException implements Exception {
  ApiException(this.message, this.kind);

  final String message;
  final ApiErrorKind kind;

  @override
  String toString() => message;
}
