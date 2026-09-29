import 'dart:convert';

import 'package:daystar_sales/forms/mobile_layout.dart';
import 'package:daystar_sales/forms/mobile_layout_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const site = 'https://crm-staging.thedaystar.co.za';

Map<String, Object?> sampleQuickLayout() => {
  'doctype': 'CRM Lead',
  'mode': 'quick',
  'source': 'Mobile Field Layout',
  'tabs': [
    {
      'sections': [
        {
          'label': 'Who',
          'columns': [
            {
              'fields': [
                {
                  'fieldname': 'first_name',
                  'fieldtype': 'Data',
                  'label': 'First name',
                  'reqd': 1,
                  'hidden': 0,
                  'options': null,
                },
              ],
            },
          ],
        },
      ],
    },
  ],
};

http.Response jsonResp(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('MobileLayoutService.fetch', () {
    test('GETs mobile_layout.get with doctype+mode and Bearer token', () async {
      late http.Request captured;
      final client = MockClient((r) async {
        captured = r;
        return jsonResp({'message': sampleQuickLayout()}, 200);
      });

      final service = MobileLayoutService(
        siteUrl: site,
        client: client,
        accessToken: () async => 'tok-123',
      );
      final layout = await service.fetch(doctype: 'CRM Lead', mode: 'quick');

      expect(captured.method, 'GET');
      expect(
        captured.url.toString(),
        contains(
          'mobile_layout.get?doctype=CRM+Lead&mode=quick',
        ),
      );
      expect(captured.headers['Authorization'], 'Bearer tok-123');
      expect(layout, isA<MobileLayout>());
      expect(layout.doctype, 'CRM Lead');
      expect(layout.fieldNames, ['first_name']);
    });

    test('propagates a typed error on non-2xx', () async {
      final client = MockClient((r) async => jsonResp({}, 403));
      final service = MobileLayoutService(
        siteUrl: site,
        client: client,
        accessToken: () async => 'tok',
      );
      expect(
        () => service.fetch(doctype: 'CRM Lead', mode: 'quick'),
        throwsA(isA<MobileLayoutException>()),
      );
    });
  });
}
