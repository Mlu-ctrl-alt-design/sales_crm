import 'package:daystar_sales/forms/mobile_layout.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shaped like the response from `daystar_mobile.api.mobile_layout.get` —
/// pulled from a real bench call on `crm-staging` (see server-side tests).
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
                {
                  'fieldname': 'last_name',
                  'fieldtype': 'Data',
                  'label': 'Last name',
                  'reqd': 0,
                  'hidden': 0,
                  'options': null,
                },
              ],
            },
            {
              'fields': [
                {
                  'fieldname': 'email',
                  'fieldtype': 'Data',
                  'label': 'Email',
                  'reqd': 0,
                  'hidden': 0,
                  'options': 'Email',
                },
              ],
            },
          ],
        },
        {
          'label': 'About',
          'columns': [
            {
              'fields': [
                {
                  'fieldname': 'territory',
                  'fieldtype': 'Link',
                  'label': 'Territory',
                  'reqd': 0,
                  'hidden': 0,
                  'options': 'CRM Territory',
                },
              ],
            },
          ],
        },
      ],
    },
  ],
};

void main() {
  group('MobileLayout.fromJson', () {
    test('parses the doctype, mode, and source', () {
      final layout = MobileLayout.fromJson(sampleQuickLayout());
      expect(layout.doctype, 'CRM Lead');
      expect(layout.mode, 'quick');
      expect(layout.source, 'Mobile Field Layout');
    });

    test('flattens tabs → sections → columns → fields, preserving order', () {
      final layout = MobileLayout.fromJson(sampleQuickLayout());
      expect(layout.tabs, hasLength(1));
      expect(layout.tabs.first.sections, hasLength(2));
      expect(
        layout.tabs.first.sections.map((s) => s.label).toList(),
        ['Who', 'About'],
      );
      expect(
        layout.fieldNames,
        ['first_name', 'last_name', 'email', 'territory'],
      );
    });

    test('parses field metadata a form can render from', () {
      final layout = MobileLayout.fromJson(sampleQuickLayout());
      final firstName = layout.fieldByName('first_name')!;
      expect(firstName.fieldtype, 'Data');
      expect(firstName.label, 'First name');
      expect(firstName.reqd, isTrue);
      expect(firstName.hidden, isFalse);

      final territory = layout.fieldByName('territory')!;
      expect(territory.fieldtype, 'Link');
      expect(territory.options, 'CRM Territory');
    });
  });
}
