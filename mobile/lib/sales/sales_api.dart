import '../api/api_client.dart';
import '../quick_send/models.dart';
import 'models.dart';

/// `daystar_mobile.api.sales`: lead → opportunity → quote → invoice.
abstract class SalesApi {
  Future<List<LeadRow>> listLeads(LeadFilter filter, String text);

  Future<LeadDetail> getLead(String name);

  Future<LeadDetail> createLead(NewLead lead);

  Future<OpportunityDetail> leadToOpportunity(
    String lead, {
    double? amount,
    DateTime? expectedClosing,
  });

  Future<List<OpportunityRow>> listOpportunities(
    OpportunityFilter filter,
    String text,
  );

  Future<OpportunityDetail> getOpportunity(String name);

  Future<OpportunityDetail> createOpportunity(
    String customer, {
    double? amount,
    DateTime? expectedClosing,
    String? notes,
  });

  Future<CustomerOption> createCustomer({
    required String name,
    required bool isCompany,
    String? email,
    String? mobile,
  });

  /// The customer for a lead or opportunity; made the first time, the same
  /// one after that.
  Future<CustomerOption> makeCustomer({String? lead, String? opportunity});
}

class HttpSalesApi implements SalesApi {
  HttpSalesApi(this._client);

  final ApiClient _client;
  static const _base = 'daystar_mobile.api.sales';

  @override
  Future<List<LeadRow>> listLeads(LeadFilter filter, String text) async {
    final result = await _client.get('$_base.list_leads', {
      'filter': filter.key,
      'txt': text,
      'limit': '50',
    });
    return [
      for (final row in (result as List? ?? const []))
        LeadRow.fromJson(row as Map<String, dynamic>),
    ];
  }

  @override
  Future<LeadDetail> getLead(String name) async => LeadDetail.fromJson(
    await _client.get('$_base.get_lead', {'name': name})
        as Map<String, dynamic>,
  );

  @override
  Future<LeadDetail> createLead(NewLead lead) async => LeadDetail.fromJson(
    await _client.post('$_base.create_lead', lead.toRequest())
        as Map<String, dynamic>,
  );

  @override
  Future<OpportunityDetail> leadToOpportunity(
    String lead, {
    double? amount,
    DateTime? expectedClosing,
  }) async => OpportunityDetail.fromJson(
    await _client.post('$_base.lead_to_opportunity', {
          'lead': lead,
          'amount': ?amount,
          'expected_closing': ?_date(expectedClosing),
        })
        as Map<String, dynamic>,
  );

  @override
  Future<List<OpportunityRow>> listOpportunities(
    OpportunityFilter filter,
    String text,
  ) async {
    final result = await _client.get('$_base.list_opportunities', {
      'filter': filter.key,
      'txt': text,
      'limit': '50',
    });
    return [
      for (final row in (result as List? ?? const []))
        OpportunityRow.fromJson(row as Map<String, dynamic>),
    ];
  }

  @override
  Future<OpportunityDetail> getOpportunity(String name) async =>
      OpportunityDetail.fromJson(
        await _client.get('$_base.get_opportunity', {'name': name})
            as Map<String, dynamic>,
      );

  @override
  Future<OpportunityDetail> createOpportunity(
    String customer, {
    double? amount,
    DateTime? expectedClosing,
    String? notes,
  }) async => OpportunityDetail.fromJson(
    await _client.post('$_base.create_opportunity', {
          'customer': customer,
          'amount': ?amount,
          'expected_closing': ?_date(expectedClosing),
          'notes': ?notes,
        })
        as Map<String, dynamic>,
  );

  @override
  Future<CustomerOption> createCustomer({
    required String name,
    required bool isCompany,
    String? email,
    String? mobile,
  }) async => CustomerOption.fromJson(
    await _client.post('$_base.create_customer', {
          'customer_name': name,
          'customer_type': isCompany ? 'Company' : 'Individual',
          'email_id': ?email,
          'mobile_no': ?mobile,
        })
        as Map<String, dynamic>,
  );

  @override
  Future<CustomerOption> makeCustomer({
    String? lead,
    String? opportunity,
  }) async => CustomerOption.fromJson(
    await _client.post('$_base.make_customer', {
          'lead': ?lead,
          'opportunity': ?opportunity,
        })
        as Map<String, dynamic>,
  );

  /// ERPNext's `yyyy-mm-dd`.
  static String? _date(DateTime? day) => day == null
      ? null
      : '${day.year}-${day.month.toString().padLeft(2, '0')}-'
            '${day.day.toString().padLeft(2, '0')}';
}
