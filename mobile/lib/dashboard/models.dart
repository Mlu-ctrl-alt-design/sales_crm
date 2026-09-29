const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// A period the dashboard can show, as `daystar_mobile.api.dashboard`
/// names it: one of the presets, or any whole month ("month:2026-07").
class DashboardPeriod {
  const DashboardPeriod._(this.key, this.label, {this.month});

  /// That calendar month; the current month runs to date.
  factory DashboardPeriod.month(int year, int month) {
    final key = '$year-${month.toString().padLeft(2, '0')}';
    return DashboardPeriod._(
      'month:$key',
      '${_monthNames[month - 1]} $year',
      month: DateTime(year, month),
    );
  }

  static const thisMonth = DashboardPeriod._('this_month', 'This month');
  static const lastMonth = DashboardPeriod._('last_month', 'Last month');
  static const thisQuarter = DashboardPeriod._('this_quarter', 'This quarter');
  static const thisYear = DashboardPeriod._('this_fy', 'This year');

  /// The presets, in picker order.
  static const values = [thisMonth, lastMonth, thisQuarter, thisYear];

  final String key;
  final String label;

  /// Set for a chosen month (its first day).
  final DateTime? month;

  @override
  bool operator ==(Object other) =>
      other is DashboardPeriod && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'DashboardPeriod($key)';
}

/// A figure for the period and the same figure for the stretch before it.
class Figure {
  const Figure(this.value, this.previous);

  final double value;
  final double previous;

  double get change => value - previous;

  /// Null when there's nothing to compare against.
  double? get changeRatio =>
      previous == 0 ? null : (value - previous) / previous.abs();

  factory Figure.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const {};
    return Figure(_d(map['value']), _d(map['previous']));
  }
}

class PeriodSpan {
  const PeriodSpan({
    required this.from,
    required this.to,
    required this.previousFrom,
    required this.previousTo,
  });

  final DateTime from;
  final DateTime to;
  final DateTime previousFrom;
  final DateTime previousTo;

  factory PeriodSpan.fromJson(Map<String, dynamic> json) => PeriodSpan(
    from: DateTime.parse(json['from'] as String),
    to: DateTime.parse(json['to'] as String),
    previousFrom: DateTime.parse(json['previous_from'] as String),
    previousTo: DateTime.parse(json['previous_to'] as String),
  );
}

class Pipeline {
  const Pipeline({
    required this.newLeads,
    required this.openLeads,
    required this.openOpportunities,
    required this.openOpportunitiesValue,
    required this.openQuotes,
    required this.openQuotesValue,
  });

  final Figure newLeads;
  final int openLeads;
  final int openOpportunities;
  final double openOpportunitiesValue;
  final int openQuotes;
  final double openQuotesValue;

  factory Pipeline.fromJson(Map<String, dynamic> json) {
    final opportunities = _map(json['open_opportunities']);
    final quotes = _map(json['open_quotes']);
    return Pipeline(
      newLeads: Figure.fromJson(json['new_leads']),
      openLeads: _i(json['open_leads']),
      openOpportunities: _i(opportunities['count']),
      openOpportunitiesValue: _d(opportunities['value']),
      openQuotes: _i(quotes['count']),
      openQuotesValue: _d(quotes['value']),
    );
  }
}

/// What the dashboard shows: the owner's company view or a rep's own.
sealed class DashboardData {
  const DashboardData({
    required this.currency,
    required this.span,
    required this.pipeline,
    required this.fetchedAt,
  });

  final String currency;
  final PeriodSpan span;
  final Pipeline pipeline;
  final DateTime fetchedAt;

  factory DashboardData.fromJson(Map<String, dynamic> json, DateTime now) {
    final currency = (json['currency'] as String?) ?? 'ZAR';
    final span = PeriodSpan.fromJson(_map(json['period']));
    final pipeline = Pipeline.fromJson(_map(json['pipeline']));
    final kpis = _map(json['kpis']);
    if (json['view'] == 'owner') {
      final sales = _map(kpis['sales']);
      final receivables = _map(kpis['receivables']);
      return OwnerDashboard(
        currency: currency,
        span: span,
        pipeline: pipeline,
        fetchedAt: now,
        profit: Figure.fromJson(kpis['profit']),
        sales: Figure.fromJson(sales),
        invoiceCount: _i(sales['count']),
        paidOut: Figure.fromJson(kpis['paid_out']),
        receivables: Figure.fromJson(receivables),
        overdue: _d(receivables['overdue']),
      );
    }
    final outstanding = _map(kpis['my_outstanding']);
    return RepDashboard(
      currency: currency,
      span: span,
      pipeline: pipeline,
      fetchedAt: now,
      linked: json['linked'] == true,
      mySales: Figure.fromJson(kpis['my_sales']),
      outstanding: _d(outstanding['value']),
      overdue: _d(outstanding['overdue']),
      outstandingInvoices: _i(outstanding['count']),
    );
  }
}

class OwnerDashboard extends DashboardData {
  const OwnerDashboard({
    required super.currency,
    required super.span,
    required super.pipeline,
    required super.fetchedAt,
    required this.profit,
    required this.sales,
    required this.invoiceCount,
    required this.paidOut,
    required this.receivables,
    required this.overdue,
  });

  /// Net profit from the Profit and Loss Statement (invoiced, not cash).
  final Figure profit;

  /// Sales invoiced, net of VAT.
  final Figure sales;
  final int invoiceCount;
  final Figure paidOut;

  /// Owed to Daystar at the end of the period, per Accounts Receivable.
  final Figure receivables;
  final double overdue;
}

class RepDashboard extends DashboardData {
  const RepDashboard({
    required super.currency,
    required super.span,
    required super.pipeline,
    required super.fetchedAt,
    required this.linked,
    required this.mySales,
    required this.outstanding,
    required this.overdue,
    required this.outstandingInvoices,
  });

  /// False until the login is linked to a Sales Person (via Employee).
  final bool linked;

  /// The rep's share of invoiced sales, by Sales Team contribution.
  final Figure mySales;
  final double outstanding;
  final double overdue;
  final int outstandingInvoices;
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

double _d(Object? value) => switch (value) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s) ?? 0,
  _ => 0,
};

int _i(Object? value) => value is num ? value.toInt() : 0;
