/// What the quick-send flow creates.
enum DocKind {
  quote('Quotation', 'Quote'),
  invoice('Sales Invoice', 'Invoice');

  const DocKind(this.doctype, this.label);

  /// The ERPNext DocType.
  final String doctype;

  /// "Quote" / "Invoice", for buttons and headings.
  final String label;

  String get noun => label.toLowerCase();

  static DocKind fromDoctype(String doctype) =>
      values.firstWhere((k) => k.doctype == doctype, orElse: () => quote);
}

class CustomerOption {
  const CustomerOption({
    required this.name,
    required this.customerName,
    this.email,
    this.mobile,
  });

  /// The Customer's id in ERPNext.
  final String name;
  final String customerName;
  final String? email;
  final String? mobile;

  factory CustomerOption.fromJson(Map<String, dynamic> json) => CustomerOption(
    name: json['name'] as String,
    customerName: (json['customer_name'] as String?) ?? json['name'] as String,
    email: json['email_id'] as String?,
    mobile: json['mobile_no'] as String?,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'customer_name': customerName,
    'email_id': email,
    'mobile_no': mobile,
  };
}

class ItemOption {
  const ItemOption({
    required this.itemCode,
    required this.itemName,
    required this.uom,
    this.rate,
  });

  final String itemCode;
  final String itemName;
  final String uom;

  /// The customer's Price List rate; null when the item has no price.
  final double? rate;

  factory ItemOption.fromJson(Map<String, dynamic> json) => ItemOption(
    itemCode: json['item_code'] as String,
    itemName: (json['item_name'] as String?) ?? json['item_code'] as String,
    uom: (json['uom'] as String?) ?? '',
    rate: _toDouble(json['rate']),
  );
}

class ItemSearch {
  const ItemSearch({required this.items, this.priceList, this.currency});

  final List<ItemOption> items;
  final String? priceList;
  final String? currency;

  factory ItemSearch.fromJson(Map<String, dynamic> json) => ItemSearch(
    priceList: json['price_list'] as String?,
    currency: json['currency'] as String?,
    items: [
      for (final item in (json['items'] as List? ?? const []))
        ItemOption.fromJson(item as Map<String, dynamic>),
    ],
  );
}

/// A document as the server built it: from `preview` (unsaved) or `submit`.
class DocSummary {
  const DocSummary({
    required this.kind,
    required this.customer,
    required this.customerName,
    required this.currency,
    required this.canEditPrices,
    required this.lines,
    required this.taxes,
    required this.netTotal,
    required this.totalTaxes,
    required this.total,
    this.name,
    this.send,
  });

  final DocKind kind;

  /// Null until submitted.
  final String? name;
  final String customer;
  final String customerName;
  final String currency;

  /// False for the Mobile Sales Rep role: rates come from the Price List.
  final bool canEditPrices;
  final List<SummaryLine> lines;
  final List<TaxLine> taxes;
  final double netTotal;
  final double totalTaxes;

  /// What the customer pays (rounded total, unless rounding is off).
  final double total;

  /// Defaults for the send screen; only on a submitted document.
  final SendDefaults? send;

  factory DocSummary.fromJson(Map<String, dynamic> json) {
    final send = json['send'];
    return DocSummary(
      kind: DocKind.fromDoctype(json['doctype'] as String),
      name: json['name'] as String?,
      customer: json['customer'] as String,
      customerName:
          (json['customer_name'] as String?) ?? json['customer'] as String,
      currency: (json['currency'] as String?) ?? 'ZAR',
      canEditPrices: json['can_edit_prices'] == true,
      lines: [
        for (final line in (json['items'] as List? ?? const []))
          SummaryLine.fromJson(line as Map<String, dynamic>),
      ],
      taxes: [
        for (final tax in (json['taxes'] as List? ?? const []))
          TaxLine.fromJson(tax as Map<String, dynamic>),
      ],
      netTotal: _toDouble(json['net_total']) ?? 0,
      totalTaxes: _toDouble(json['total_taxes']) ?? 0,
      total: _toDouble(json['total']) ?? 0,
      send: send is Map<String, dynamic> ? SendDefaults.fromJson(send) : null,
    );
  }
}

/// A submitted quote or invoice in the "send again" list.
class DocListing {
  const DocListing({
    required this.kind,
    required this.name,
    required this.customerName,
    required this.currency,
    required this.total,
    this.date,
    this.status,
  });

  final DocKind kind;
  final String name;
  final String customerName;
  final String currency;
  final double total;

  /// The quote's date or the invoice's posting date.
  final DateTime? date;

  /// ERPNext's status, e.g. "Open", "Ordered", "Paid", "Overdue".
  final String? status;

  factory DocListing.fromJson(Map<String, dynamic> json) => DocListing(
    kind: DocKind.fromDoctype(json['doctype'] as String),
    name: json['name'] as String,
    customerName: (json['customer_name'] as String?) ?? '',
    currency: (json['currency'] as String?) ?? 'ZAR',
    total: _toDouble(json['total']) ?? 0,
    date: DateTime.tryParse('${json['date']}'),
    status: json['status'] as String?,
  );
}

class SummaryLine {
  const SummaryLine({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.uom,
    required this.rate,
    required this.amount,
    this.priceListRate,
  });

  final String itemCode;
  final String itemName;
  final double qty;
  final String uom;
  final double rate;
  final double? priceListRate;
  final double amount;

  factory SummaryLine.fromJson(Map<String, dynamic> json) => SummaryLine(
    itemCode: json['item_code'] as String,
    itemName: (json['item_name'] as String?) ?? json['item_code'] as String,
    qty: _toDouble(json['qty']) ?? 0,
    uom: (json['uom'] as String?) ?? '',
    rate: _toDouble(json['rate']) ?? 0,
    priceListRate: _toDouble(json['price_list_rate']),
    amount: _toDouble(json['amount']) ?? 0,
  );
}

class TaxLine {
  const TaxLine({required this.description, required this.amount, this.rate});

  final String description;
  final double? rate;
  final double amount;

  factory TaxLine.fromJson(Map<String, dynamic> json) => TaxLine(
    description: (json['description'] as String?) ?? 'Tax',
    rate: _toDouble(json['rate']),
    amount: _toDouble(json['amount']) ?? 0,
  );
}

class SendDefaults {
  const SendDefaults({this.to, this.from, this.subject, this.message});

  final String? to;

  /// The address the email will come from; null when none is set up.
  final String? from;
  final String? subject;
  final String? message;

  factory SendDefaults.fromJson(Map<String, dynamic> json) => SendDefaults(
    to: json['to'] as String?,
    from: json['from'] as String?,
    subject: json['subject'] as String?,
    message: json['message'] as String?,
  );
}

double? _toDouble(Object? value) => switch (value) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s),
  _ => null,
};
