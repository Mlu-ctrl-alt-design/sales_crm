import 'package:daystar_sales/api/api_client.dart';
import 'package:daystar_sales/quick_send/draft.dart';
import 'package:daystar_sales/theme/daystar_theme.dart';
import 'package:daystar_sales/theme/money.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

Future<void> openQuickSend(
  WidgetTester tester, {
  FakeQuickSendApi? api,
  MemoryStore? drafts,
  List<String>? shared,
}) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DaystarTheme.light(),
      home: testHome(api: api, drafts: drafts, shared: shared),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('QUICK SEND'));
  await tester.pumpAndSettle();
}

Future<void> chooseCustomer(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('choose-customer')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('customer-CUST-0001')));
  await tester.pumpAndSettle();
}

Future<void> addItem(WidgetTester tester, String code) async {
  await tester.tap(find.byKey(const Key('add-item')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('item-$code')));
  await tester.pumpAndSettle();
}

String totalText(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  testWidgets('quote: customer, items, review, submit, email, share', (
    tester,
  ) async {
    final api = FakeQuickSendApi();
    final shared = <String>[];
    await openQuickSend(tester, api: api, shared: shared);

    await tester.tap(find.text('Quote'));
    await tester.pumpAndSettle();
    await chooseCustomer(tester);
    expect(find.text('Acme Farms'), findsOneWidget);

    await addItem(tester, 'PANEL-450');
    await addItem(tester, 'BRACKET');
    await tester.tap(find.byKey(const Key('qty-plus-PANEL-450')));
    await tester.pumpAndSettle();

    // Totals come from the server preview: (2 × 2400 + 150) + 15% VAT.
    final total = formatZar((2 * 2400 + 150) * 1.15);
    expect(totalText(tester, 'draft-total'), total);

    await tester.tap(find.byKey(const Key('review')));
    await tester.pumpAndSettle();
    expect(find.text('Review quote'), findsOneWidget);
    expect(totalText(tester, 'review-total'), total);

    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    expect(find.text('SAL-QTN-2026-00001'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('email-to')))
          .controller!
          .text,
      'buyer@acme.co.za',
    );

    await tester.tap(find.byKey(const Key('send-email')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email-sent')), findsOneWidget);
    expect(api.emails.single.name, 'SAL-QTN-2026-00001');
    expect(api.emails.single.to, ['buyer@acme.co.za']);

    await tester.tap(find.text('Share PDF'));
    await tester.pumpAndSettle();
    expect(api.pdfDownloads, ['SAL-QTN-2026-00001']);
    expect(shared, ['SAL-QTN-2026-00001.pdf']);

    // Done: back to an empty draft for the next one.
    await tester.tap(find.byKey(const Key('receipt-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('choose-customer')), findsOneWidget);
  });

  testWidgets('a lost submit answer keeps entries and never duplicates', (
    tester,
  ) async {
    final api = FakeQuickSendApi()..loseNextAnswer = true;
    await openQuickSend(tester, api: api);
    await chooseCustomer(tester);
    await addItem(tester, 'PANEL-450');
    await tester.tap(find.byKey(const Key('review')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('submit-error')), findsOneWidget);
    expect(find.textContaining("won't be created twice"), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('ACC-SINV-2026-00001'), findsOneWidget);
    expect(api.created, hasLength(1));
    expect(api.submitKeys, hasLength(2));
    expect(api.submitKeys.toSet(), hasLength(1), reason: 'same key on retry');
  });

  testWidgets('a refused submit shows the reason and keeps the draft', (
    tester,
  ) async {
    final drafts = MemoryStore();
    final api = FakeQuickSendApi()
      ..submitError = ApiException(
        'Row 1: rate for PANEL-450 must be R 2 400,00. Ask the owner.',
        ApiErrorKind.notPermitted,
      );
    await openQuickSend(tester, api: api, drafts: drafts);
    await chooseCustomer(tester);
    await addItem(tester, 'PANEL-450');
    await tester.tap(find.byKey(const Key('review')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('must be R 2 400,00'), findsOneWidget);
    final saved = await QuickSendDraft.load(drafts);
    expect(saved.lines.single.itemCode, 'PANEL-450');
  });

  testWidgets('a rep taps a price and is told why it is locked', (
    tester,
  ) async {
    final api = FakeQuickSendApi()..canEditPrices = false;
    await openQuickSend(tester, api: api);
    await chooseCustomer(tester);
    await addItem(tester, 'PANEL-450');

    await tester.tap(find.byKey(const Key('rate-PANEL-450')));
    await tester.pump();

    expect(find.byKey(const Key('price-locked')), findsOneWidget);
    expect(find.byKey(const Key('rate-input')), findsNothing);
  });

  testWidgets('the owner can set their own price', (tester) async {
    final api = FakeQuickSendApi();
    await openQuickSend(tester, api: api);
    await chooseCustomer(tester);
    await addItem(tester, 'PANEL-450');

    await tester.tap(find.byKey(const Key('rate-PANEL-450')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('rate-input')), '2000');
    await tester.tap(find.byKey(const Key('rate-save')));
    await tester.pumpAndSettle();

    expect(totalText(tester, 'draft-total'), formatZar(2000 * 1.15));
    expect(find.text('OWN PRICE'), findsOneWidget);
  });

  testWidgets('a preview refusal shows inline and blocks review', (
    tester,
  ) async {
    final api = FakeQuickSendApi()
      ..previewError = ApiException(
        'Row 1: PANEL-450 has no price in Price List Standard Selling.',
        ApiErrorKind.notPermitted,
      );
    await openQuickSend(tester, api: api);
    await chooseCustomer(tester);
    await addItem(tester, 'PANEL-450');

    expect(find.byKey(const Key('preview-error')), findsOneWidget);
    expect(find.textContaining('has no price'), findsOneWidget);
    final review = tester.widget<FilledButton>(find.byKey(const Key('review')));
    expect(review.onPressed, isNull);
  });

  testWidgets('removing the last item clears the total', (tester) async {
    await openQuickSend(tester);
    await chooseCustomer(tester);
    await addItem(tester, 'BRACKET');
    expect(totalText(tester, 'draft-total'), formatZar(150 * 1.15));

    await tester.tap(find.byKey(const Key('qty-minus-BRACKET')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('line-BRACKET')), findsNothing);
    expect(totalText(tester, 'draft-total'), '—');
  });

  testWidgets('an unfinished draft is there after a restart', (tester) async {
    final drafts = MemoryStore();
    final draft = await QuickSendDraft.load(drafts);
    draft
      ..setCustomer(acme)
      ..addItem(bracket);

    await openQuickSend(tester, drafts: drafts);

    expect(find.text('Acme Farms'), findsOneWidget);
    expect(find.byKey(const Key('line-BRACKET')), findsOneWidget);
    expect(totalText(tester, 'draft-total'), formatZar(150 * 1.15));
  });

  testWidgets('+ New quote switches the draft to a quote', (tester) async {
    final drafts = MemoryStore();
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: DaystarTheme.light(),
        home: testHome(drafts: drafts),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quick-create')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-quote')));
    await tester.pumpAndSettle();

    expect(find.text('Review quote'), findsOneWidget);
  });
}
