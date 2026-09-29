import 'package:daystar_sales/api/api_client.dart';
import 'package:daystar_sales/sales/models.dart';
import 'package:daystar_sales/theme/daystar_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'quick_send_flow_test.dart' show addItem;
import 'support/fakes.dart';

Future<void> openSales(
  WidgetTester tester, {
  FakeSalesApi? sales,
  FakeQuickSendApi? api,
  MemoryStore? drafts,
}) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DaystarTheme.light(),
      home: testHome(sales: sales, api: api, drafts: drafts),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('SALES'));
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('leads list: cards, filters and search', (tester) async {
    final sales = FakeSalesApi();
    await openSales(tester, sales: sales);

    expect(find.byKey(const Key('lead-CRM-LEAD-2026-00001')), findsOneWidget);
    expect(find.text('Bright Farms'), findsOneWidget);
    expect(find.text('thandi@bright.co.za'), findsOneWidget);
    expect(sales.leadFilters.last, LeadFilter.open);

    await tapKey(tester, 'lead-filter-unassigned');
    expect(sales.leadFilters.last, LeadFilter.unassigned);
    expect(find.byKey(const Key('lead-CRM-LEAD-2026-00001')), findsNothing);
    expect(find.byKey(const Key('lead-CRM-LEAD-2026-00002')), findsOneWidget);
  });

  testWidgets('capture a lead from +, then see it', (tester) async {
    final sales = FakeSalesApi();
    await openSales(tester, sales: sales);

    await tapKey(tester, 'quick-create');
    await tapKey(tester, 'create-lead');
    expect(find.widgetWithText(AppBar, 'New lead'), findsOneWidget);

    // Needs a first name and a way to reach them.
    await tapKey(tester, 'form-save');
    expect(find.text('Add their first name.'), findsOneWidget);
    expect(find.text('Add a mobile number or an email.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('lead-first-name')), 'Lerato');
    await tester.enterText(find.byKey(const Key('lead-last-name')), 'Mokoena');
    await tester.enterText(find.byKey(const Key('lead-mobile')), '0831112222');
    await tester.enterText(find.byKey(const Key('lead-company')), 'Sun Co');
    await tapKey(tester, 'form-save');

    expect(find.widgetWithText(AppBar, 'Lead'), findsOneWidget);
    expect(find.text('Lerato Mokoena'), findsOneWidget);
    expect(find.byKey(const Key('create-opportunity')), findsOneWidget);
    expect(sales.leads.length, 3);
  });

  testWidgets(
    'lead → opportunity → quote (lead made a customer) → linked quote',
    (tester) async {
      final sales = FakeSalesApi();
      final api = FakeQuickSendApi();
      await openSales(tester, sales: sales, api: api);

      await tapKey(tester, 'lead-CRM-LEAD-2026-00001');
      await tapKey(tester, 'create-opportunity');
      await tester.enterText(
        find.byKey(const Key('opportunity-amount')),
        '48000',
      );
      await tapKey(tester, 'opportunity-save');

      expect(find.widgetWithText(AppBar, 'Opportunity'), findsOneWidget);
      expect(find.text('Bright Farms'), findsOneWidget);

      // Still a lead, so quoting asks to make them a customer first.
      await tapKey(tester, 'create-quote');
      expect(find.text('Make them a customer?'), findsOneWidget);
      await tapKey(tester, 'confirm-make-customer');

      // On Quick send with the customer and the opportunity filled in.
      expect(find.widgetWithText(AppBar, 'Quick send'), findsOneWidget);
      expect(find.byKey(const Key('draft-opportunity')), findsOneWidget);
      expect(find.textContaining('CRM-OPP-2026-00001'), findsOneWidget);
      expect(sales.leads['CRM-LEAD-2026-00001']!['status'], 'Converted');

      await addItem(tester, 'PANEL-450');
      await tapKey(tester, 'review');
      await tapKey(tester, 'submit');

      expect(api.submitOpportunities, ['CRM-OPP-2026-00001']);
    },
  );

  testWidgets('a submitted quote becomes one invoice', (tester) async {
    final api = FakeQuickSendApi();
    await openSales(tester, api: api);

    await tester.tap(find.text('QUICK SEND'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quote'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'choose-customer');
    await tapKey(tester, 'customer-CUST-0001');
    await addItem(tester, 'PANEL-450');
    await tapKey(tester, 'review');
    await tapKey(tester, 'submit');
    expect(find.text('SAL-QTN-2026-00001'), findsOneWidget);

    await tapKey(tester, 'make-invoice');
    expect(find.text('Make invoice?'), findsOneWidget);
    await tapKey(tester, 'confirm-make-invoice');

    expect(find.widgetWithText(AppBar, 'Invoice'), findsOneWidget);
    expect(find.text('Invoice submitted'.toUpperCase()), findsOneWidget);
    expect(api.invoicedQuotes, ['SAL-QTN-2026-00001']);
  });

  testWidgets('a refused invoice explains why and stays on the quote', (
    tester,
  ) async {
    final api = FakeQuickSendApi()
      ..invoiceError = ApiException(
        'Rate for Solar panel must be 2400.',
        ApiErrorKind.notPermitted,
      );
    await openSales(tester, api: api);
    await tester.tap(find.text('QUICK SEND'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quote'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'choose-customer');
    await tapKey(tester, 'customer-CUST-0001');
    await addItem(tester, 'PANEL-450');
    await tapKey(tester, 'review');
    await tapKey(tester, 'submit');

    await tapKey(tester, 'make-invoice');
    await tapKey(tester, 'confirm-make-invoice');

    expect(find.byKey(const Key('invoice-error')), findsOneWidget);
    expect(find.text('SAL-QTN-2026-00001'), findsOneWidget);
  });

  testWidgets('a new customer from + can be quoted straight away', (
    tester,
  ) async {
    final sales = FakeSalesApi();
    await openSales(tester, sales: sales);

    await tapKey(tester, 'quick-create');
    await tapKey(tester, 'create-customer');
    await tester.enterText(
      find.byKey(const Key('customer-name')),
      'Acme Farms',
    );
    await tester.enterText(
      find.byKey(const Key('customer-email')),
      'not-an-email',
    );
    await tapKey(tester, 'form-save');
    expect(find.text("That email doesn't look right."), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('customer-email')),
      'buyer@acme.co.za',
    );
    await tapKey(tester, 'form-save');

    expect(sales.createdCustomers.single.email, 'buyer@acme.co.za');
    expect(find.byKey(const Key('customer-added')), findsOneWidget);
  });

  testWidgets('starting a quote never silently drops an unfinished draft', (
    tester,
  ) async {
    final sales = FakeSalesApi();
    await openSales(tester, sales: sales);

    // An unfinished invoice on Quick send.
    await tester.tap(find.text('QUICK SEND'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'choose-customer');
    await tapKey(tester, 'customer-CUST-0001');
    await addItem(tester, 'BRACKET');

    await tester.tap(find.text('SALES'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'lead-CRM-LEAD-2026-00001');
    await tapKey(tester, 'make-customer');
    await tapKey(tester, 'confirm-make-customer');
    await tapKey(tester, 'quote-customer');

    expect(find.text('Replace the unfinished draft?'), findsOneWidget);
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Lead'), findsOneWidget);
  });
}
