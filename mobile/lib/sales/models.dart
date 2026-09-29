import '../quick_send/models.dart';

/// Which leads the list shows, as `daystar_mobile.api.sales` names them.
enum LeadFilter {
  open('open', 'Open'),
  mine('mine', 'Mine'),
  unassigned('unassigned', 'Unassigned'),
  all('all', 'All');

  const LeadFilter(this.key, this.label);

  final String key;
  final String label;
}

enum OpportunityFilter {
  open('open', 'Open'),
  mine('mine', 'Mine'),
  all('all', 'All');

  const OpportunityFilter(this.key, this.label);

  final String key;
  final String label;
}

/// Where a lead or opportunity has got to, for the stage track.
enum SalesStage {
  lead('Lead'),
  opportunity('Opportunity'),
  quote('Quote'),
  invoice('Invoice');

  const SalesStage(this.label);

  final String label;
}

class LeadRow {
  const LeadRow({
    required this.name,
    required this.leadName,
    required this.status,
    this.companyName,
    this.email,
    this.mobile,
    this.owner,
    this.created,
  });

  /// The Lead's id in ERPNext.
  final String name;
  final String leadName;
  final String? companyName;
  final String? email;
  final String? mobile;

  /// ERPNext's status: Lead, Open, Replied, Opportunity, Quotation, Converted…
  final String status;
  final String? owner;
  final DateTime? created;

  factory LeadRow.fromJson(Map<String, dynamic> json) => LeadRow(
    name: json['name'] as String,
    leadName: _text(json['lead_name']) ?? json['name'] as String,
    companyName: _text(json['company_name']),
    email: _text(json['email_id']),
    mobile: _text(json['mobile_no']),
    status: _text(json['status']) ?? 'Lead',
    owner: _text(json['lead_owner']),
    created: DateTime.tryParse('${json['created']}'),
  );
}

class LeadDetail {
  const LeadDetail({
    required this.lead,
    required this.opportunities,
    required this.canConvert,
    this.firstName,
    this.lastName,
    this.phone,
    this.website,
    this.city,
    this.source,
    this.notes,
    this.customer,
  });

  final LeadRow lead;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? website;
  final String? city;
  final String? source;

  /// The latest note on the lead.
  final String? notes;

  /// Set once the lead has been made a customer.
  final CustomerOption? customer;
  final List<OpportunityRow> opportunities;

  /// Whether this user may create opportunities.
  final bool canConvert;

  SalesStage get stage {
    if (opportunities.any((o) => o.status == 'Quotation')) {
      return SalesStage.quote;
    }
    if (opportunities.isNotEmpty) return SalesStage.opportunity;
    return SalesStage.lead;
  }

  factory LeadDetail.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    return LeadDetail(
      lead: LeadRow.fromJson(json),
      firstName: _text(json['first_name']),
      lastName: _text(json['last_name']),
      phone: _text(json['phone']),
      website: _text(json['website']),
      city: _text(json['city']),
      source: _text(json['source']),
      notes: _text(json['notes']),
      customer: customer is Map<String, dynamic>
          ? CustomerOption.fromJson(customer)
          : null,
      opportunities: [
        for (final row in (json['opportunities'] as List? ?? const []))
          OpportunityRow.fromJson(row as Map<String, dynamic>),
      ],
      canConvert: json['can_convert'] != false,
    );
  }
}

class OpportunityRow {
  const OpportunityRow({
    required this.name,
    required this.from,
    required this.partyName,
    required this.title,
    required this.status,
    required this.amount,
    this.salesStage,
    this.currency,
    this.expectedClosing,
    this.owner,
    this.created,
  });

  final String name;

  /// "Lead" or "Customer".
  final String from;
  final String partyName;
  final String title;

  /// Open, Replied, Quotation, Converted, Lost, Closed.
  final String status;
  final String? salesStage;
  final double amount;
  final String? currency;
  final DateTime? expectedClosing;
  final String? owner;
  final DateTime? created;

  factory OpportunityRow.fromJson(Map<String, dynamic> json) => OpportunityRow(
    name: json['name'] as String,
    from: _text(json['opportunity_from']) ?? 'Lead',
    partyName: _text(json['party_name']) ?? '',
    title: _text(json['title']) ?? json['name'] as String,
    status: _text(json['status']) ?? 'Open',
    salesStage: _text(json['sales_stage']),
    amount: _toDouble(json['amount']),
    currency: _text(json['currency']),
    expectedClosing: DateTime.tryParse('${json['expected_closing']}'),
    owner: _text(json['opportunity_owner']),
    created: DateTime.tryParse('${json['created']}'),
  );
}

class OpportunityDetail {
  const OpportunityDetail({
    required this.opportunity,
    required this.quotes,
    this.contactEmail,
    this.contactMobile,
    this.notes,
    this.customer,
  });

  final OpportunityRow opportunity;
  final String? contactEmail;
  final String? contactMobile;
  final String? notes;

  /// Null while the opportunity is still with a lead that isn't a customer.
  final CustomerOption? customer;
  final List<QuoteRow> quotes;

  SalesStage get stage => quotes.any((q) => q.submitted)
      ? SalesStage.quote
      : SalesStage.opportunity;

  factory OpportunityDetail.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    return OpportunityDetail(
      opportunity: OpportunityRow.fromJson(json),
      contactEmail: _text(json['contact_email']),
      contactMobile: _text(json['contact_mobile']),
      notes: _text(json['notes']),
      customer: customer is Map<String, dynamic>
          ? CustomerOption.fromJson(customer)
          : null,
      quotes: [
        for (final row in (json['quotes'] as List? ?? const []))
          QuoteRow.fromJson(row as Map<String, dynamic>),
      ],
    );
  }
}

class QuoteRow {
  const QuoteRow({
    required this.name,
    required this.status,
    required this.submitted,
    required this.currency,
    required this.total,
    this.date,
  });

  final String name;
  final String status;

  /// False for a draft saved in Desk.
  final bool submitted;
  final String currency;
  final double total;
  final DateTime? date;

  factory QuoteRow.fromJson(Map<String, dynamic> json) => QuoteRow(
    name: json['name'] as String,
    status: _text(json['status']) ?? '',
    submitted: json['submitted'] == true,
    currency: _text(json['currency']) ?? 'ZAR',
    total: _toDouble(json['total']),
    date: DateTime.tryParse('${json['date']}'),
  );
}

/// What the new-lead form sends.
class NewLead {
  const NewLead({
    required this.firstName,
    this.lastName,
    this.mobile,
    this.email,
    this.companyName,
    this.notes,
  });

  final String firstName;
  final String? lastName;
  final String? mobile;
  final String? email;
  final String? companyName;
  final String? notes;

  Map<String, Object?> toRequest() => {
    'first_name': firstName,
    'last_name': ?lastName,
    'mobile_no': ?mobile,
    'email_id': ?email,
    'company_name': ?companyName,
    'notes': ?notes,
  };
}

String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

double _toDouble(Object? value) => switch (value) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s) ?? 0,
  _ => 0,
};
