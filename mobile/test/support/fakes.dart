import 'dart:convert';
import 'dart:typed_data';

import 'package:daystar_sales/api/api_client.dart';
import 'package:daystar_sales/auth/auth_repository.dart';
import 'package:daystar_sales/auth/biometric_lock.dart';
import 'package:daystar_sales/auth/device_prefs.dart';
import 'package:daystar_sales/auth/key_value_store.dart';
import 'package:daystar_sales/dashboard/dashboard_api.dart';
import 'package:daystar_sales/dashboard/models.dart';
import 'package:daystar_sales/quick_send/draft.dart';
import 'package:daystar_sales/quick_send/models.dart';
import 'package:daystar_sales/quick_send/quick_send_api.dart';
import 'package:daystar_sales/sales/models.dart';
import 'package:daystar_sales/sales/sales_api.dart';
import 'package:daystar_sales/shell/home_shell.dart';
import 'package:daystar_sales/startup/app_status.dart';
import 'package:daystar_sales/startup/app_status_service.dart';

class FakeStatusService implements AppStatusService {
  FakeStatusService(this.result);
  final Future<AppStatus> Function() result;

  @override
  Future<AppStatus> fetch() => result();
}

class FakeAuth implements AuthRepository {
  FakeAuth({this.stored});

  Session? stored;
  int logins = 0;

  @override
  Future<Session?> restore() async => stored;

  @override
  Future<Session> login({
    required String username,
    required String password,
  }) async {
    logins++;
    return stored = Session(user: username);
  }

  @override
  Future<void> logout() async => stored = null;
}

class MemoryPrefs implements DevicePrefs {
  String? email;
  bool unlock = false;
  bool offered = false;

  @override
  Future<String?> lastEmail() async => email;
  @override
  Future<void> setLastEmail(String value) async => email = value;
  @override
  Future<bool> biometricUnlock() async => unlock;
  @override
  Future<void> setBiometricUnlock(bool enabled) async => unlock = enabled;
  @override
  Future<bool> biometricOffered() async => offered;
  @override
  Future<void> setBiometricOffered() async => offered = true;
}

class FakeBiometrics implements BiometricLock {
  FakeBiometrics({this.kind = BiometricKind.face, this.succeeds = true});

  BiometricKind? kind;
  bool succeeds;
  int prompts = 0;

  @override
  Future<BiometricKind?> available() async => kind;

  @override
  Future<bool> unlock(String reason) async {
    prompts++;
    return succeeds;
  }
}

const openStatus = AppStatus(enabled: true, maintenanceMode: false);

class MemoryStore implements KeyValueStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

const acme = CustomerOption(
  name: 'CUST-0001',
  customerName: 'Acme Farms',
  email: 'buyer@acme.co.za',
);
const panel = ItemOption(
  itemCode: 'PANEL-450',
  itemName: 'Solar panel 450W',
  uom: 'Nos',
  rate: 2400,
);
const bracket = ItemOption(
  itemCode: 'BRACKET',
  itemName: 'Roof bracket',
  uom: 'Nos',
  rate: 150,
);

/// Behaves like `daystar_mobile.api.documents` with 15% VAT.
class FakeQuickSendApi implements QuickSendApi {
  List<CustomerOption> customers = [acme];
  List<ItemOption> items = [panel, bracket];
  bool canEditPrices = true;
  ApiException? previewError;

  /// Next submit creates the document but the answer never arrives.
  bool loseNextAnswer = false;

  /// Next submit is refused outright.
  ApiException? submitError;
  ApiException? emailError;

  final submitKeys = <String>[];

  /// The opportunity each submit was linked to, in order.
  final submitOpportunities = <String?>[];
  final invoicedQuotes = <String>[];
  ApiException? invoiceError;
  final created = <String, DocSummary>{};
  final emails = <({String name, List<String> to})>[];
  final pdfDownloads = <String>[];
  int previews = 0;

  @override
  Future<List<CustomerOption>> searchCustomers(String text) async => [
    for (final c in customers)
      if (c.customerName.toLowerCase().contains(text.toLowerCase())) c,
  ];

  @override
  Future<ItemSearch> searchItems(String customer, String text) async =>
      ItemSearch(
        currency: 'ZAR',
        priceList: 'Standard Selling',
        items: [
          for (final i in items)
            if (i.itemName.toLowerCase().contains(text.toLowerCase())) i,
        ],
      );

  @override
  Future<List<DocListing>> searchDocuments(DocKind kind, String text) async => [
    for (final doc in created.values)
      if (doc.kind == kind &&
          '${doc.name} ${doc.customerName}'.toLowerCase().contains(
            text.toLowerCase(),
          ))
        DocListing(
          kind: kind,
          name: doc.name!,
          customerName: doc.customerName,
          currency: doc.currency,
          total: doc.total,
          date: DateTime(2026, 9, 12),
          status: 'Open',
        ),
  ];

  @override
  Future<DocSummary> getDocument(DocKind kind, String name) async =>
      created.values.firstWhere((doc) => doc.name == name);

  @override
  Future<DocSummary> preview(
    DocKind kind,
    String customer,
    List<DraftLine> lines, {
    String? opportunity,
  }) async {
    previews++;
    if (previewError != null) throw previewError!;
    return _build(kind, customer, lines);
  }

  @override
  Future<DocSummary> submit(
    DocKind kind,
    String customer,
    List<DraftLine> lines,
    String key, {
    String? opportunity,
  }) async {
    submitKeys.add(key);
    submitOpportunities.add(opportunity);
    if (submitError != null) {
      final error = submitError!;
      submitError = null;
      throw error;
    }
    final doc = created[key] ??= _build(
      kind,
      customer,
      lines,
      name:
          '${kind == DocKind.quote ? 'SAL-QTN' : 'ACC-SINV'}-2026-'
          '${(created.length + 1).toString().padLeft(5, '0')}',
    );
    if (loseNextAnswer) {
      loseNextAnswer = false;
      throw ApiException('No answer', ApiErrorKind.offline);
    }
    return doc;
  }

  /// Like `sales.quote_to_invoice`: one invoice per quote.
  @override
  Future<DocSummary> invoiceFromQuote(String quotation) async {
    invoicedQuotes.add(quotation);
    if (invoiceError != null) throw invoiceError!;
    final quote = created.values.firstWhere((doc) => doc.name == quotation);
    return created['invoice-$quotation'] ??= DocSummary(
      kind: DocKind.invoice,
      name: 'ACC-SINV-2026-${(created.length + 1).toString().padLeft(5, '0')}',
      customer: quote.customer,
      customerName: quote.customerName,
      currency: quote.currency,
      canEditPrices: quote.canEditPrices,
      lines: quote.lines,
      taxes: quote.taxes,
      netTotal: quote.netTotal,
      totalTaxes: quote.totalTaxes,
      total: quote.total,
      send: quote.send,
    );
  }

  @override
  Future<String> sendEmail(
    DocKind kind,
    String name,
    List<String> to, {
    String? subject,
    String? message,
  }) async {
    if (emailError != null) throw emailError!;
    emails.add((name: name, to: to));
    return 'mlu@thedaystar.co.za';
  }

  @override
  Future<Uint8List> downloadPdf(DocKind kind, String name) async {
    pdfDownloads.add(name);
    return Uint8List.fromList(utf8.encode('%PDF-1.4'));
  }

  DocSummary _build(
    DocKind kind,
    String customer,
    List<DraftLine> lines, {
    String? name,
  }) {
    final summaryLines = [
      for (final line in lines)
        () {
          final rate =
              line.rate ??
              items.firstWhere((i) => i.itemCode == line.itemCode).rate ??
              0;
          return SummaryLine(
            itemCode: line.itemCode,
            itemName: line.itemName,
            qty: line.qty,
            uom: line.uom,
            rate: rate,
            priceListRate: items
                .firstWhere((i) => i.itemCode == line.itemCode)
                .rate,
            amount: rate * line.qty,
          );
        }(),
    ];
    final net = summaryLines.fold<double>(0, (sum, l) => sum + l.amount);
    final vat = net * 0.15;
    return DocSummary(
      kind: kind,
      name: name,
      customer: customer,
      customerName: customers
          .firstWhere((c) => c.name == customer)
          .customerName,
      currency: 'ZAR',
      canEditPrices: canEditPrices,
      lines: summaryLines,
      taxes: [TaxLine(description: 'VAT 15%', rate: 15, amount: vat)],
      netTotal: net,
      totalTaxes: vat,
      total: net + vat,
      send: name == null
          ? null
          : const SendDefaults(
              to: 'buyer@acme.co.za',
              from: 'mlu@thedaystar.co.za',
            ),
    );
  }
}

/// The signed-in app with quick-send fakes.
HomeShell testHome({
  FakeDashboardApi? dashboard,
  FakeQuickSendApi? api,
  FakeSalesApi? sales,
  MemoryStore? drafts,
  List<String>? shared,
}) => HomeShell(
  dashboard: dashboard ?? FakeDashboardApi(),
  quickSend: api ?? FakeQuickSendApi(),
  sales: sales ?? FakeSalesApi(),
  drafts: drafts ?? MemoryStore(),
  sharePdf: (pdf, fileName, {origin}) async => shared?.add(fileName),
);

/// Shaped like `daystar_mobile.api.dashboard.get`, owner view by default.
class FakeDashboardApi implements DashboardApi {
  FakeDashboardApi({
    this.json,
    this.error,
    Map<DashboardPeriod, DashboardData>? saved,
  }) : saved = saved ?? {};

  Map<String, dynamic>? json;
  Object? error;

  /// What's kept on the device, as [HttpDashboardApi] keeps it.
  final Map<DashboardPeriod, DashboardData> saved;
  final calls = <(DashboardPeriod, bool)>[];

  @override
  Future<DashboardData?> cached(DashboardPeriod period) async => saved[period];

  @override
  Future<DashboardData> get(
    DashboardPeriod period, {
    bool refresh = false,
  }) async {
    calls.add((period, refresh));
    if (error != null) throw error!;
    return saved[period] = DashboardData.fromJson(
      json ?? ownerJson(),
      DateTime(2026, 9, 27, 18, 52),
    );
  }
}

Map<String, dynamic> _period() => {
  'key': 'this_month',
  'from': '2026-09-01',
  'to': '2026-09-27',
  'previous_from': '2026-08-01',
  'previous_to': '2026-08-27',
};

Map<String, dynamic> _pipeline() => {
  'new_leads': {'value': 6, 'previous': 4},
  'open_leads': 11,
  'open_opportunities': {'count': 3, 'value': 84000},
  'open_quotes': {'count': 5, 'value': 126500},
};

Map<String, dynamic> ownerJson() => {
  'view': 'owner',
  'company': 'Daystar',
  'currency': 'ZAR',
  'period': _period(),
  'kpis': {
    'profit': {'value': 48250, 'previous': 43000},
    'sales': {'value': 186400, 'previous': 201000, 'count': 14},
    'paid_out': {'value': 92150, 'previous': 88000},
    'receivables': {'value': 138150, 'previous': 120000, 'overdue': 24600},
  },
  'pipeline': _pipeline(),
};

Map<String, dynamic> repJson({bool linked = true}) => {
  'view': 'rep',
  'company': 'Daystar',
  'currency': 'ZAR',
  'period': _period(),
  'linked': linked,
  'kpis': {
    'my_sales': {'value': 32000, 'previous': 30000},
    'my_outstanding': {'value': 12400, 'overdue': 0, 'count': 2},
  },
  'pipeline': _pipeline(),
};

/// Behaves like `daystar_mobile.api.sales`, in memory.
class FakeSalesApi implements SalesApi {
  FakeSalesApi() {
    leads['CRM-LEAD-2026-00001'] = _leadJson(
      'CRM-LEAD-2026-00001',
      'Thandi Nkosi',
      company: 'Bright Farms',
      email: 'thandi@bright.co.za',
      mobile: '0821234567',
    );
    leads['CRM-LEAD-2026-00002'] = _leadJson(
      'CRM-LEAD-2026-00002',
      'Sipho Dlamini',
      mobile: '0739876543',
      owner: null,
    );
  }

  final leads = <String, Map<String, dynamic>>{};
  final opportunities = <String, Map<String, dynamic>>{};

  /// Lead name → customer, once made.
  final customers = <String, CustomerOption>{};
  final leadFilters = <LeadFilter>[];
  final createdCustomers = <CustomerOption>[];
  ApiException? error;

  Map<String, dynamic> _leadJson(
    String name,
    String leadName, {
    String? company,
    String? email,
    String? mobile,
    String? owner = 'mlu@thedaystar.co.za',
    String status = 'Lead',
  }) => {
    'name': name,
    'lead_name': leadName,
    'company_name': company,
    'email_id': email,
    'mobile_no': mobile,
    'status': status,
    'lead_owner': owner,
    'created': '2026-09-20',
  };

  @override
  Future<List<LeadRow>> listLeads(LeadFilter filter, String text) async {
    leadFilters.add(filter);
    if (error != null) throw error!;
    return [
      for (final json in leads.values.toList().reversed)
        if ((filter != LeadFilter.unassigned || json['lead_owner'] == null) &&
            '${json['lead_name']} ${json['company_name']}'
                .toLowerCase()
                .contains(text.toLowerCase()))
          LeadRow.fromJson(json),
    ];
  }

  @override
  Future<LeadDetail> getLead(String name) async {
    final json = leads[name]!;
    final customer = customers[name];
    return LeadDetail.fromJson({
      ...json,
      'customer': customer?.toJson(),
      'opportunities': [
        for (final o in opportunities.values)
          if (o['opportunity_from'] == 'Lead' && o['party_name'] == name) o,
      ],
      'can_convert': true,
    });
  }

  @override
  Future<LeadDetail> createLead(NewLead lead) async {
    if (error != null) throw error!;
    final name =
        'CRM-LEAD-2026-${(leads.length + 1).toString().padLeft(5, '0')}';
    leads[name] = {
      ..._leadJson(
        name,
        [lead.firstName, ?lead.lastName].join(' '),
        company: lead.companyName,
        email: lead.email,
        mobile: lead.mobile,
      ),
      'first_name': lead.firstName,
      'notes': lead.notes,
    };
    return getLead(name);
  }

  @override
  Future<OpportunityDetail> leadToOpportunity(
    String lead, {
    double? amount,
    DateTime? expectedClosing,
  }) async {
    final json = leads[lead]!;
    json['status'] = 'Opportunity';
    return _addOpportunity(
      from: 'Lead',
      party: lead,
      title: (json['company_name'] ?? json['lead_name']) as String,
      amount: amount,
    );
  }

  @override
  Future<List<OpportunityRow>> listOpportunities(
    OpportunityFilter filter,
    String text,
  ) async => [
    for (final json in opportunities.values) OpportunityRow.fromJson(json),
  ];

  @override
  Future<OpportunityDetail> getOpportunity(String name) async {
    final json = opportunities[name]!;
    final customer = json['opportunity_from'] == 'Customer'
        ? CustomerOption(
            name: json['party_name'] as String,
            customerName: json['title'] as String,
          )
        : customers[json['party_name']];
    return OpportunityDetail.fromJson({
      ...json,
      'customer': customer?.toJson(),
      'quotes': const [],
    });
  }

  @override
  Future<OpportunityDetail> createOpportunity(
    String customer, {
    double? amount,
    DateTime? expectedClosing,
    String? notes,
  }) async => _addOpportunity(
    from: 'Customer',
    party: customer,
    title: customer,
    amount: amount,
  );

  Future<OpportunityDetail> _addOpportunity({
    required String from,
    required String party,
    required String title,
    double? amount,
  }) {
    final name =
        'CRM-OPP-2026-${(opportunities.length + 1).toString().padLeft(5, '0')}';
    opportunities[name] = {
      'name': name,
      'opportunity_from': from,
      'party_name': party,
      'title': title,
      'status': 'Open',
      'amount': amount ?? 0,
      'currency': 'ZAR',
      'created': '2026-09-29',
    };
    return getOpportunity(name);
  }

  @override
  Future<CustomerOption> createCustomer({
    required String name,
    required bool isCompany,
    String? email,
    String? mobile,
  }) async {
    final customer = CustomerOption(
      name: name,
      customerName: name,
      email: email,
      mobile: mobile,
    );
    createdCustomers.add(customer);
    return customer;
  }

  @override
  Future<CustomerOption> makeCustomer({
    String? lead,
    String? opportunity,
  }) async {
    lead ??= opportunities[opportunity]!['party_name'] as String;
    final json = leads[lead]!;
    json['status'] = 'Converted';
    return customers[lead] ??= CustomerOption(
      // Shares acme's id so the quick-send fake can price for it.
      name: acme.name,
      customerName: (json['company_name'] ?? json['lead_name']) as String,
      email: json['email_id'] as String?,
    );
  }
}
