import 'package:daystar_sales/api/api_client.dart';
import 'package:daystar_sales/assistant/assistant_api.dart';
import 'package:daystar_sales/theme/daystar_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

Future<void> openAssistant(WidgetTester tester, FakeAssistantApi api) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DaystarTheme.light(),
      home: testHome(assistant: api),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('ASSISTANT'));
  await tester.pumpAndSettle();
}

Future<void> ask(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('assistant-input')), text);
  await tester.pump();
  await tester.tap(find.byKey(const Key('assistant-send')));
  await tester.pumpAndSettle();
}

/// A quote for Acme Farms, as `documents.preview` returns it.
Map<String, dynamic> quoteJson({String? name}) => {
  'doctype': 'Quotation',
  'name': name,
  'customer': 'CUST-0001',
  'customer_name': 'Acme Farms',
  'currency': 'ZAR',
  'can_edit_prices': true,
  'items': [
    {
      'item_code': 'PANEL-450',
      'item_name': 'Solar panel 450W',
      'qty': 2,
      'uom': 'Nos',
      'rate': 2400,
      'amount': 4800,
    },
  ],
  'taxes': const [],
  'net_total': 4800,
  'total_taxes': 720,
  'total': 5520,
  if (name != null)
    'send': {'to': 'buyer@acme.co.za', 'from': 'mlu@thedaystar.co.za'},
};

AssistantReply proposeQuote() => AssistantReply.fromJson({
  'status': 'confirm_required',
  'reply': 'I can submit a quote for Acme Farms for R 5 520,00.',
  'pending_action_id': 'APA-0001',
  'tool_name': 'submit_document',
  'arguments': {'doctype': 'Quotation', 'customer': 'CUST-0001'},
  'preview': quoteJson(),
});

void main() {
  testWidgets('an empty chat offers suggestions; a question gets an answer', (
    tester,
  ) async {
    final api = FakeAssistantApi([
      const AssistantReply(
        status: ReplyStatus.answered,
        reply: 'Sales this month are R 186 400,00.',
      ),
    ]);
    await openAssistant(tester, api);

    expect(find.text('Ask about the business'), findsOneWidget);
    expect(find.text('How are sales this month?'), findsOneWidget);
    // The + button would cover the message box.
    expect(find.byKey(const Key('quick-create')), findsNothing);

    await tester.tap(find.text('How are sales this month?'));
    await tester.pumpAndSettle();

    expect(api.messages, ['How are sales this month?']);
    expect(find.text('Sales this month are R 186 400,00.'), findsOneWidget);
  });

  testWidgets('a proposed quote waits for Confirm, then opens to send', (
    tester,
  ) async {
    final api = FakeAssistantApi([proposeQuote()])
      ..confirmResult = quoteJson(name: 'SAL-QTN-2026-00001');
    await openAssistant(tester, api);

    await ask(tester, 'Quote Acme 2 panels');
    expect(find.text('NEEDS YOUR OK'), findsOneWidget);
    expect(find.text('Submit quote for Acme Farms'), findsOneWidget);
    expect(find.text('2 × Solar panel 450W'), findsOneWidget);
    expect(api.confirmed, isEmpty);

    await tester.tap(find.byKey(const Key('action-confirm')));
    await tester.pumpAndSettle();

    expect(api.confirmed, ['APA-0001']);
    expect(find.text('DONE'), findsOneWidget);
    expect(find.byKey(const Key('action-confirm')), findsNothing);
    expect(find.textContaining('SAL-QTN-2026-00001'), findsOneWidget);

    await tester.tap(find.byKey(const Key('action-open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('receipt-name')), findsOneWidget);
    expect(find.byKey(const Key('make-invoice')), findsOneWidget);
  });

  testWidgets('Cancel rejects the action and nothing runs', (tester) async {
    final api = FakeAssistantApi([proposeQuote()]);
    await openAssistant(tester, api);

    await ask(tester, 'Quote Acme 2 panels');
    await tester.tap(find.byKey(const Key('action-cancel')));
    await tester.pumpAndSettle();

    expect(api.cancelled, ['APA-0001']);
    expect(api.confirmed, isEmpty);
    expect(find.text('CANCELLED'), findsOneWidget);
    expect(find.byKey(const Key('action-confirm')), findsNothing);
  });

  testWidgets('an expired action says so and can be tried again', (
    tester,
  ) async {
    final api = FakeAssistantApi([proposeQuote()])
      ..confirmError = ApiException(
        'This action expired; ask the assistant again.',
        ApiErrorKind.rejected,
      );
    await openAssistant(tester, api);

    await ask(tester, 'Quote Acme 2 panels');
    await tester.tap(find.byKey(const Key('action-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('action-error')), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('earlier turns go back with the next message', (tester) async {
    final api = FakeAssistantApi([
      proposeQuote(),
      const AssistantReply(status: ReplyStatus.answered, reply: 'Sent.'),
    ])..confirmResult = quoteJson(name: 'SAL-QTN-2026-00001');
    await openAssistant(tester, api);

    await ask(tester, 'Quote Acme 2 panels');
    await tester.tap(find.byKey(const Key('action-confirm')));
    await tester.pumpAndSettle();
    await ask(tester, 'Email it to them');

    final history = api.histories.last;
    expect(history.map((m) => m['role']), ['user', 'assistant']);
    expect(history.first['content'], 'Quote Acme 2 panels');
    // The model is told what came of its proposal.
    expect(
      history.last['content'] as String,
      contains(
        'The user confirmed and it was done: Quotation '
        'SAL-QTN-2026-00001 submitted',
      ),
    );
  });

  testWidgets('no signal: the message can be sent again', (tester) async {
    final api = FakeAssistantApi([
      ApiException("Couldn't reach Daystar.", ApiErrorKind.offline),
      const AssistantReply(status: ReplyStatus.answered, reply: 'Here now.'),
    ]);
    await openAssistant(tester, api);

    await ask(tester, 'Who owes us the most?');
    expect(find.byKey(const Key('assistant-error')), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(api.messages, ['Who owes us the most?', 'Who owes us the most?']);
    expect(find.text('Here now.'), findsOneWidget);
    expect(find.text('Who owes us the most?'), findsOneWidget);
    // A failed turn never goes into the history.
    expect(api.histories.last, isEmpty);
  });

  testWidgets('the chat survives switching tabs; New chat clears it', (
    tester,
  ) async {
    final api = FakeAssistantApi([
      const AssistantReply(status: ReplyStatus.answered, reply: 'Hello.'),
    ]);
    await openAssistant(tester, api);
    await ask(tester, 'Hi');

    await tester.tap(find.text('DASHBOARD'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ASSISTANT'));
    await tester.pumpAndSettle();
    expect(find.text('Hello.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('new-chat')));
    await tester.pumpAndSettle();
    expect(find.text('Ask about the business'), findsOneWidget);
  });
}
