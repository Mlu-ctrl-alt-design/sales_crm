import 'package:daystar_sales/quick_send/draft.dart';
import 'package:daystar_sales/quick_send/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('a draft survives the app closing, key and all', () async {
    final store = MemoryStore();
    final draft = await QuickSendDraft.load(store);
    draft
      ..setKind(DocKind.quote)
      ..setCustomer(acme)
      ..addItem(panel)
      ..addItem(panel)
      ..addItem(bracket)
      ..setRate(1, 120);

    final reopened = await QuickSendDraft.load(store);

    expect(reopened.kind, DocKind.quote);
    expect(reopened.customer?.name, acme.name);
    expect(reopened.lines.map((l) => (l.itemCode, l.qty, l.rate)), [
      ('PANEL-450', 2.0, null),
      ('BRACKET', 1.0, 120.0),
    ]);
    expect(reopened.key, draft.key);
  });

  test(
    'the submit key stays put through edits; clear makes a new one',
    () async {
      final draft = await QuickSendDraft.load(MemoryStore());
      final key = draft.key;
      expect(key, matches(RegExp(r'^[0-9a-f]{32}$')));

      draft
        ..setCustomer(acme)
        ..addItem(panel)
        ..setQty(0, 3);
      expect(draft.key, key);

      draft.clear();
      expect(draft.key, isNot(key));
      expect(draft.isEmpty, isTrue);
    },
  );

  test(
    'qty to zero removes the line; rate null goes back to the list',
    () async {
      final draft = await QuickSendDraft.load(MemoryStore());
      draft
        ..addItem(panel)
        ..addItem(bracket)
        ..setRate(0, 2000)
        ..setRate(0, null)
        ..setQty(1, 0);

      expect(draft.lines, hasLength(1));
      expect(draft.lines.single.rate, isNull);
      expect(draft.lines.single.toRequest(), {
        'item_code': 'PANEL-450',
        'qty': 1.0,
      });
    },
  );

  test('an unreadable saved draft starts fresh', () async {
    final store = MemoryStore()..values['quick_send_draft'] = '{not json';
    final draft = await QuickSendDraft.load(store);
    expect(draft.isEmpty, isTrue);
  });
}
