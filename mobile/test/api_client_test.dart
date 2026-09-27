import 'dart:convert';
import 'dart:io';

import 'package:daystar_sales/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const site = 'https://crm-staging.thedaystar.co.za';

/// Frappe's error body: `_server_messages` is a JSON list of JSON strings.
String frappeError(String excType, String message, {String? title}) =>
    jsonEncode({
      'exception': 'frappe.exceptions.$excType: $message',
      'exc_type': excType,
      '_server_messages': jsonEncode([
        jsonEncode({
          'message': message,
          'title': ?title,
          'indicator': 'red',
          'raise_exception': 1,
        }),
      ]),
    });

ApiClient clientFor(
  Future<http.Response> Function(http.Request) handler, {
  String? token = 'gAAAAtoken',
}) => ApiClient(
  siteUrl: site,
  accessToken: () async => token,
  client: MockClient(handler),
);

void main() {
  test('sends the Mobile Control bearer token and returns message', () async {
    late http.Request seen;
    final api = clientFor((request) async {
      seen = request;
      return http.Response(jsonEncode({'message': 'pong'}), 200);
    });

    final result = await api.post('daystar_mobile.api.documents.preview', {
      'doctype': 'Quotation',
    });

    expect(result, 'pong');
    expect(seen.headers['Authorization'], 'Bearer gAAAAtoken');
    expect(seen.headers['Content-Type'], startsWith('application/json'));
    expect(
      seen.url.toString(),
      '$site/api/method/daystar_mobile.api.documents.preview',
    );
    expect(jsonDecode(seen.body), {'doctype': 'Quotation'});
  });

  test('a price-lock refusal reads as its plain message', () async {
    final api = clientFor(
      (_) async => http.Response(
        frappeError(
          'PermissionError',
          'Row 1: rate for <strong>PANEL-450</strong> must be R 2 400,00 '
              'from Price List <strong>Standard Selling</strong>. '
              'Ask the owner to change prices.',
          title: 'Price locked',
        ),
        403,
      ),
    );

    await expectLater(
      api.post('x', {}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiErrorKind.notPermitted)
            .having(
              (e) => e.message,
              'message',
              'Row 1: rate for PANEL-450 must be R 2 400,00 from Price List '
                  'Standard Selling. Ask the owner to change prices.',
            ),
      ),
    );
  });

  test('a validation error is "rejected" with the server message', () async {
    final api = clientFor(
      (_) async => http.Response(
        frappeError('ValidationError', 'Add at least one item.'),
        417,
      ),
    );
    await expectLater(
      api.post('x', {}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiErrorKind.rejected)
            .having((e) => e.message, 'message', 'Add at least one item.'),
      ),
    );
  });

  test('falls back to the exception text without _server_messages', () async {
    final api = clientFor(
      (_) async => http.Response(
        jsonEncode({
          'exception': 'frappe.exceptions.ValidationError: Invalid key.',
          'exc_type': 'ValidationError',
        }),
        417,
      ),
    );
    await expectLater(
      api.get('x'),
      throwsA(
        isA<ApiException>().having((e) => e.message, 'm', 'Invalid key.'),
      ),
    );
  });

  test('401 means signed out', () async {
    final api = clientFor(
      (_) async => http.Response(
        frappeError('AuthenticationError', 'Invalid authentication token'),
        401,
      ),
    );
    await expectLater(
      api.get('x'),
      throwsA(
        isA<ApiException>().having((e) => e.kind, 'k', ApiErrorKind.signedOut),
      ),
    );
  });

  test('no token: signed out without calling the server', () async {
    var calls = 0;
    final api = clientFor((_) async {
      calls++;
      return http.Response('{}', 200);
    }, token: null);
    await expectLater(
      api.get('x'),
      throwsA(
        isA<ApiException>().having((e) => e.kind, 'k', ApiErrorKind.signedOut),
      ),
    );
    expect(calls, 0);
  });

  test('no connection is "offline"', () async {
    final api = clientFor(
      (_) async => throw const SocketException('Network is unreachable'),
    );
    await expectLater(
      api.get('x'),
      throwsA(
        isA<ApiException>().having((e) => e.kind, 'k', ApiErrorKind.offline),
      ),
    );
  });

  test('a server crash does not leak a traceback', () async {
    final api = clientFor(
      (_) async => http.Response(
        jsonEncode({'exception': 'Traceback (most recent call last): ...'}),
        500,
      ),
    );
    await expectLater(
      api.get('x'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.kind, 'k', ApiErrorKind.server)
            .having((e) => e.message, 'm', isNot(contains('Traceback'))),
      ),
    );
  });

  test('download returns the raw bytes', () async {
    final api = clientFor((request) async {
      expect(request.url.queryParameters, {
        'doctype': 'Quotation',
        'name': 'SAL-QTN-2026-00001',
      });
      return http.Response.bytes(utf8.encode('%PDF-1.4'), 200);
    });
    final bytes = await api.download('frappe.utils.print_format.download_pdf', {
      'doctype': 'Quotation',
      'name': 'SAL-QTN-2026-00001',
    });
    expect(utf8.decode(bytes), '%PDF-1.4');
  });
}
