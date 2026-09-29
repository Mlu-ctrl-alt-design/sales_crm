import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../auth/key_value_store.dart';
import 'models.dart';

class DraftLine {
  const DraftLine({
    required this.itemCode,
    required this.itemName,
    required this.uom,
    required this.qty,
    this.rate,
  });

  final String itemCode;
  final String itemName;
  final String uom;
  final double qty;

  /// An owner's own rate; null means the Price List rate.
  final double? rate;

  DraftLine copyWith({double? qty, double? rate, bool clearRate = false}) =>
      DraftLine(
        itemCode: itemCode,
        itemName: itemName,
        uom: uom,
        qty: qty ?? this.qty,
        rate: clearRate ? null : rate ?? this.rate,
      );

  /// A row for `preview` / `submit`.
  Map<String, Object?> toRequest() => {
    'item_code': itemCode,
    'qty': qty,
    'rate': ?rate,
  };

  Map<String, Object?> toJson() => {
    'item_code': itemCode,
    'item_name': itemName,
    'uom': uom,
    'qty': qty,
    'rate': rate,
  };

  factory DraftLine.fromJson(Map<String, dynamic> json) => DraftLine(
    itemCode: json['item_code'] as String,
    itemName: json['item_name'] as String,
    uom: (json['uom'] as String?) ?? '',
    qty: (json['qty'] as num).toDouble(),
    rate: (json['rate'] as num?)?.toDouble(),
  );
}

/// The opportunity a quote is being made for.
class DraftOpportunity {
  const DraftOpportunity({required this.name, required this.title});

  final String name;
  final String title;

  Map<String, Object?> toJson() => {'name': name, 'title': title};

  factory DraftOpportunity.fromJson(Map<String, dynamic> json) =>
      DraftOpportunity(
        name: json['name'] as String,
        title: (json['title'] as String?) ?? json['name'] as String,
      );
}

/// The quote or invoice being put together, saved on every change so it
/// survives the app closing, a lock or a failed submit.
///
/// [key] identifies this draft to `submit`. It stays the same through every
/// retry, so a submit whose answer got lost can't create a second document;
/// only [clear] (after a successful submit, or "Start over") makes a new one.
class QuickSendDraft extends ChangeNotifier {
  QuickSendDraft._(
    this._store,
    this._kind,
    this._customer,
    this._lines,
    this._key, [
    this._opportunity,
  ]);

  /// The saved draft, or a new empty one.
  static Future<QuickSendDraft> load(KeyValueStore store) async {
    final raw = await store.read(_storageKey);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final customer = json['customer'];
        final opportunity = json['opportunity'];
        return QuickSendDraft._(
          store,
          DocKind.values.byName(json['kind'] as String),
          customer is Map<String, dynamic>
              ? CustomerOption.fromJson(customer)
              : null,
          [
            for (final line in json['lines'] as List)
              DraftLine.fromJson(line as Map<String, dynamic>),
          ],
          json['key'] as String,
          opportunity is Map<String, dynamic>
              ? DraftOpportunity.fromJson(opportunity)
              : null,
        );
      } on Object {
        // Unreadable (e.g. from an older build): start fresh.
      }
    }
    return QuickSendDraft._(store, DocKind.invoice, null, [], newKey());
  }

  static const _storageKey = 'quick_send_draft';

  final KeyValueStore _store;
  DocKind _kind;
  CustomerOption? _customer;
  List<DraftLine> _lines;
  String _key;
  DraftOpportunity? _opportunity;

  DocKind get kind => _kind;
  CustomerOption? get customer => _customer;
  List<DraftLine> get lines => List.unmodifiable(_lines);
  String get key => _key;

  /// Only ever set on a quote.
  DraftOpportunity? get opportunity =>
      _kind == DocKind.quote ? _opportunity : null;
  bool get isEmpty => _customer == null && _lines.isEmpty;
  bool get isReady => _customer != null && _lines.isNotEmpty;

  void setKind(DocKind kind) {
    if (kind == _kind) return;
    _kind = kind;
    _changed();
  }

  /// A different customer drops the opportunity: it was someone else's.
  void setCustomer(CustomerOption customer) {
    if (customer.name != _customer?.name) _opportunity = null;
    _customer = customer;
    _changed();
  }

  void clearOpportunity() {
    _opportunity = null;
    _changed();
  }

  /// A fresh draft for [customer], e.g. a quote for an opportunity.
  void startFor(
    DocKind kind,
    CustomerOption customer, {
    DraftOpportunity? opportunity,
  }) {
    _kind = kind;
    _customer = customer;
    _opportunity = opportunity;
    _lines = [];
    _key = newKey();
    _changed();
  }

  /// Adds one of [item], or one more if it's already on the draft.
  void addItem(ItemOption item) {
    final i = _lines.indexWhere((l) => l.itemCode == item.itemCode);
    if (i == -1) {
      _lines = [
        ..._lines,
        DraftLine(
          itemCode: item.itemCode,
          itemName: item.itemName,
          uom: item.uom,
          qty: 1,
        ),
      ];
    } else {
      _lines = [..._lines]..[i] = _lines[i].copyWith(qty: _lines[i].qty + 1);
    }
    _changed();
  }

  /// Zero or less removes the line.
  void setQty(int index, double qty) {
    _lines = [..._lines];
    if (qty <= 0) {
      _lines.removeAt(index);
    } else {
      _lines[index] = _lines[index].copyWith(qty: qty);
    }
    _changed();
  }

  /// Null goes back to the Price List rate.
  void setRate(int index, double? rate) {
    _lines = [..._lines]
      ..[index] = _lines[index].copyWith(rate: rate, clearRate: rate == null);
    _changed();
  }

  void removeLine(int index) => setQty(index, 0);

  /// Empties the draft for the next document, keeping quote/invoice.
  void clear() {
    _customer = null;
    _opportunity = null;
    _lines = [];
    _key = newKey();
    _changed();
  }

  void _changed() {
    notifyListeners();
    _store.write(_storageKey, jsonEncode(_toJson()));
  }

  Map<String, Object?> _toJson() => {
    'kind': _kind.name,
    'customer': _customer?.toJson(),
    'lines': [for (final line in _lines) line.toJson()],
    'key': _key,
    'opportunity': _opportunity?.toJson(),
  };

  /// 32 random hex characters.
  @visibleForTesting
  static String newKey() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
