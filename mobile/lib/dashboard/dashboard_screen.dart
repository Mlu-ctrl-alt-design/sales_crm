import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme/daystar_theme.dart';
import '../theme/money.dart';
import 'dashboard_api.dart';
import 'dates.dart';
import 'models.dart';

/// Sales health on one screen: one main number, each figure with its
/// period and its change against the comparable stretch before it.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.api,
    this.now = DateTime.now,
  });

  final DashboardApi api;
  final DateTime Function() now;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardPeriod _period = DashboardPeriod.thisMonth;

  /// Kept per period so switching back is instant.
  final _loaded = <DashboardPeriod, DashboardData>{};
  String? _error;
  bool _loading = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _show(_period);
  }

  /// The last figures fetched for [period], from memory or the device; the
  /// server is only asked when there are none, or on pull to refresh.
  Future<void> _show(DashboardPeriod period) async {
    if (_loaded.containsKey(period)) return;
    DashboardData? saved;
    try {
      saved = await widget.api.cached(period);
    } catch (_) {
      saved = null;
    }
    if (!mounted) return;
    if (saved == null) {
      if (period == _period) await _load();
      return;
    }
    setState(() => _loaded[period] = saved!);
  }

  Future<void> _load({bool refresh = false}) async {
    final period = _period;
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.api.get(period, refresh: refresh);
      if (!mounted || request != _request) return;
      setState(() {
        _loaded[period] = data;
        _loading = false;
      });
    } catch (e) {
      // Anything, not just ApiException: an unexpected reply must end the
      // spinner rather than leave it turning.
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        // A reply for a period no longer on screen isn't this one's error.
        if (period != _period) return;
        _error = e is ApiException
            ? e.message
            : "Daystar sent back figures the app couldn't read.";
      });
    }
  }

  Future<void> _chooseMonth() async {
    final month = await showModalBottomSheet<DashboardPeriod>(
      context: context,
      builder: (_) => _MonthSheet(
        now: widget.now(),
        initial: _period.month ?? widget.now(),
      ),
    );
    if (month != null) _select(month);
  }

  void _select(DashboardPeriod period) {
    if (period == _period) return;
    setState(() {
      _period = period;
      _error = null;
    });
    _show(period);
  }

  @override
  Widget build(BuildContext context) {
    final data = _loaded[_period];
    return RefreshIndicator(
      color: DaystarColors.accent,
      onRefresh: () => _load(refresh: true),
      child: ListView(
        // Room at the end to scroll clear of the + button.
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 112),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _PeriodPicker(
            selected: _period,
            onSelected: _select,
            onChooseMonth: _chooseMonth,
          ),
          if (data == null && _error == null)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (data == null)
            _LoadError(message: _error!, onRetry: _load)
          else ...[
            _SpanLine(data: data, now: widget.now(), refreshing: _loading),
            if (_error != null) _StaleNote(message: _error!),
            switch (data) {
              OwnerDashboard() => _OwnerBody(data: data, now: widget.now()),
              RepDashboard() => _RepBody(data: data, now: widget.now()),
            },
          ],
        ],
      ),
    );
  }
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({
    required this.selected,
    required this.onSelected,
    required this.onChooseMonth,
  });

  final DashboardPeriod selected;
  final ValueChanged<DashboardPeriod> onSelected;
  final VoidCallback onChooseMonth;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          for (final period in DashboardPeriod.values) ...[
            ChoiceChip(
              key: Key('period-${period.key}'),
              label: Text(period.label),
              selected: period == selected,
              showCheckmark: false,
              shape: const RoundedRectangleBorder(),
              side: const BorderSide(color: DaystarColors.ink),
              backgroundColor: DaystarColors.surface,
              selectedColor: DaystarColors.ink,
              labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: period == selected
                    ? DaystarColors.surface
                    : DaystarColors.ink,
              ),
              onSelected: (_) => onSelected(period),
            ),
            const SizedBox(width: 8),
          ],
          ChoiceChip(
            key: const Key('period-month'),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(selected.month == null ? 'Pick month' : selected.label),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: selected.month == null
                      ? DaystarColors.ink
                      : DaystarColors.surface,
                ),
              ],
            ),
            selected: selected.month != null,
            showCheckmark: false,
            shape: const RoundedRectangleBorder(),
            side: const BorderSide(color: DaystarColors.ink),
            backgroundColor: DaystarColors.surface,
            selectedColor: DaystarColors.ink,
            labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected.month != null
                  ? DaystarColors.surface
                  : DaystarColors.ink,
            ),
            onSelected: (_) => onChooseMonth(),
          ),
        ],
      ),
    );
  }
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Month and year dropdowns; pops with that month's period. The current
/// month comes back as "This month", which is the same figures.
class _MonthSheet extends StatefulWidget {
  const _MonthSheet({required this.now, required this.initial});

  final DateTime now;
  final DateTime initial;

  /// How many years back the year dropdown goes.
  static const yearsBack = 5;

  @override
  State<_MonthSheet> createState() => _MonthSheetState();
}

class _MonthSheetState extends State<_MonthSheet> {
  late int _year = widget.initial.year;
  late int _month = widget.initial.month;

  bool _isFuture(int year, int month) =>
      year > widget.now.year ||
      (year == widget.now.year && month > widget.now.month);

  void _setYear(int year) => setState(() {
    _year = year;
    // A month later this year than today moves back to this month.
    if (_isFuture(_year, _month)) _month = widget.now.month;
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final now = widget.now;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Show a month', style: text.titleLarge),
            const SizedBox(height: 4),
            Text(
              'That whole month, against the month before it.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    // Rebuilt with the year, which can move the month back.
                    key: ValueKey('month-dropdown-$_year'),
                    initialValue: _month,
                    decoration: const InputDecoration(labelText: 'Month'),
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(
                          value: m,
                          enabled: !_isFuture(_year, m),
                          child: Text(
                            _monthNames[m - 1],
                            style: _isFuture(_year, m)
                                ? text.bodyLarge?.copyWith(
                                    color: DaystarColors.muted,
                                  )
                                : null,
                          ),
                        ),
                    ],
                    onChanged: (m) => setState(() => _month = m ?? _month),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    key: const Key('year-dropdown'),
                    initialValue: _year,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items: [
                      for (
                        var y = now.year;
                        y >= now.year - _MonthSheet.yearsBack;
                        y--
                      )
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged: (y) => _setYear(y ?? _year),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('month-show'),
              onPressed: () => Navigator.pop(
                context,
                _year == now.year && _month == now.month
                    ? DashboardPeriod.thisMonth
                    : DashboardPeriod.month(_year, _month),
              ),
              child: Text('Show ${_monthNames[_month - 1]} $_year'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpanLine extends StatelessWidget {
  const _SpanLine({
    required this.data,
    required this.now,
    required this.refreshing,
  });

  final DashboardData data;
  final DateTime now;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final span = data.span;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Eyebrow(
              '${rangeLabel(span.from, span.to, thisYear: now.year)} · '
              'updated ${updatedLabel(data.fetchedAt, now)}',
            ),
          ),
          if (refreshing)
            const SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
        ],
      ),
    );
  }
}

class _OwnerBody extends StatelessWidget {
  const _OwnerBody({required this.data, required this.now});

  final OwnerDashboard data;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final vs = _previousSpan(data.span, now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(
          key: const Key('kpi-profit'),
          label: 'Profit · invoiced',
          figure: data.profit,
          currency: data.currency,
          vs: vs,
        ),
        _Rule(),
        _Tile(
          key: const Key('kpi-sales'),
          label: 'Sales invoiced',
          figure: data.sales,
          currency: data.currency,
          vs: vs,
          good: _Good.up,
          note:
              '${data.invoiceCount} '
              '${data.invoiceCount == 1 ? 'invoice' : 'invoices'}, excl. VAT',
        ),
        _Tile(
          key: const Key('kpi-receivables'),
          label: 'Owed to Daystar',
          figure: data.receivables,
          currency: data.currency,
          vs: _Against(
            dayLabel(data.span.previousTo, thisYear: now.year),
            'on',
          ),
          good: _Good.down,
          note: data.overdue > 0
              ? '${formatMoney(data.overdue, data.currency)} overdue'
              : 'Nothing overdue',
          noteColor: data.overdue > 0 ? DaystarColors.moneyOut : null,
        ),
        _Tile(
          key: const Key('kpi-paid-out'),
          label: 'Paid out',
          figure: data.paidOut,
          currency: data.currency,
          vs: vs,
          good: _Good.neither,
          amountColor: DaystarColors.moneyOut,
        ),
        _PipelineSection(
          pipeline: data.pipeline,
          currency: data.currency,
          vs: vs,
          mine: false,
        ),
      ],
    );
  }
}

class _RepBody extends StatelessWidget {
  const _RepBody({required this.data, required this.now});

  final RepDashboard data;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final vs = _previousSpan(data.span, now);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!data.linked)
          Container(
            key: const Key('rep-unlinked'),
            margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            padding: const EdgeInsets.all(14),
            color: DaystarColors.subtle,
            child: Text(
              "Your login isn't linked to a sales person yet, so your sales "
              "can't show here. Ask Mlu to link you.",
              style: text.bodyMedium,
            ),
          ),
        _Hero(
          key: const Key('kpi-my-sales'),
          label: 'My sales',
          figure: data.mySales,
          currency: data.currency,
          vs: vs,
          note: 'Your share of invoices, excl. VAT',
        ),
        _Rule(),
        _Tile(
          key: const Key('kpi-my-outstanding'),
          label: 'Still owed on my invoices',
          amount: data.outstanding,
          currency: data.currency,
          note: data.overdue > 0
              ? '${formatMoney(data.overdue, data.currency)} overdue · '
                    '${data.outstandingInvoices} '
                    '${data.outstandingInvoices == 1 ? 'invoice' : 'invoices'}'
              : '${data.outstandingInvoices} '
                    '${data.outstandingInvoices == 1 ? 'invoice' : 'invoices'}'
                    ', nothing overdue',
          noteColor: data.overdue > 0 ? DaystarColors.moneyOut : null,
        ),
        _PipelineSection(
          pipeline: data.pipeline,
          currency: data.currency,
          vs: vs,
          mine: true,
        ),
      ],
    );
  }
}

enum _Good { up, down, neither }

/// What a figure is compared with: "1–27 Aug" (in), "27 Aug" (on).
class _Against {
  const _Against(this.label, this.preposition);

  final String label;
  final String preposition;
}

_Against _previousSpan(PeriodSpan span, DateTime now) => _Against(
  rangeLabel(span.previousFrom, span.previousTo, thisYear: now.year),
  'in',
);

class _Hero extends StatelessWidget {
  const _Hero({
    super.key,
    required this.label,
    required this.figure,
    required this.currency,
    required this.vs,
    this.note,
  });

  final String label;
  final Figure figure;
  final String currency;
  final _Against vs;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(label),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoney(figure.value, currency),
              key: const Key('hero-value'),
              style: text.displaySmall?.copyWith(
                fontSize: 44,
                color: figure.value < 0
                    ? DaystarColors.moneyOut
                    : DaystarColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _Change(figure: figure, currency: currency, vs: vs, good: _Good.up),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note!, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.label,
    required this.currency,
    this.figure,
    this.amount,
    this.vs,
    this.good = _Good.neither,
    this.note,
    this.noteColor,
    this.amountColor,
  });

  final String label;
  final String currency;
  final Figure? figure;

  /// For a figure with no comparison.
  final double? amount;
  final _Against? vs;
  final _Good good;
  final String? note;
  final Color? noteColor;
  final Color? amountColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final figure = this.figure;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DaystarColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Eyebrow(label)),
              Text(
                formatMoney(figure?.value ?? amount ?? 0, currency),
                style: text.titleLarge?.copyWith(
                  color: amountColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (figure != null)
            _Change(figure: figure, currency: currency, vs: vs!, good: good),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                note!,
                style: text.bodySmall?.copyWith(color: noteColor),
              ),
            ),
        ],
      ),
    );
  }
}

/// "▲ R 4 100,00 (12%) vs 1–27 Aug", coloured only when up or down is
/// clearly good or bad.
class _Change extends StatelessWidget {
  const _Change({
    required this.figure,
    required this.currency,
    required this.vs,
    required this.good,
  });

  final Figure figure;
  final String currency;
  final _Against vs;
  final _Good good;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final change = figure.change;
    if (figure.previous == 0 && figure.value == 0) {
      return Text(
        'None ${vs.preposition} ${vs.label} either',
        style: text.bodySmall,
      );
    }
    if (change.abs() < 0.005) {
      return Text(
        'Same as ${vs.preposition} ${vs.label}',
        style: text.bodySmall,
      );
    }
    final up = change > 0;
    final ratio = figure.changeRatio;
    final color = switch (good) {
      _Good.up => up ? DaystarColors.moneyIn : DaystarColors.moneyOut,
      _Good.down => up ? DaystarColors.moneyOut : DaystarColors.moneyIn,
      _Good.neither => DaystarColors.muted,
    };
    final pct = ratio == null ? '' : ' (${(ratio.abs() * 100).round()}%)';
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text:
                '${up ? '▲' : '▼'} ${formatMoney(change.abs(), currency)}$pct',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          TextSpan(text: ' vs ${vs.label}'),
        ],
      ),
      style: text.bodySmall,
    );
  }
}

class _PipelineSection extends StatelessWidget {
  const _PipelineSection({
    required this.pipeline,
    required this.currency,
    required this.vs,
    required this.mine,
  });

  final Pipeline pipeline;
  final String currency;
  final _Against vs;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget row(String key, String label, String count, String? value) =>
        Container(
          key: Key(key),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: DaystarColors.divider)),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: text.bodyLarge)),
              Text(count, style: text.titleMedium),
              if (value != null)
                SizedBox(
                  width: 128,
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: text.bodyMedium?.copyWith(
                      color: DaystarColors.muted,
                    ),
                  ),
                ),
            ],
          ),
        );

    final newLeads = pipeline.newLeads.value.round();
    final leadChange = newLeads - pipeline.newLeads.previous.round();
    final compared = leadChange == 0
        ? 'the same as'
        : '${leadChange.abs()} ${leadChange > 0 ? 'more' : 'fewer'} than';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Eyebrow(mine ? 'My pipeline · open now' : 'Pipeline · open now'),
          const SizedBox(height: 4),
          row(
            'pipeline-quotes',
            'Open quotes',
            '${pipeline.openQuotes}',
            formatMoney(pipeline.openQuotesValue, currency),
          ),
          row(
            'pipeline-opportunities',
            'Open opportunities',
            '${pipeline.openOpportunities}',
            formatMoney(pipeline.openOpportunitiesValue, currency),
          ),
          row('pipeline-leads', 'Open leads', '${pipeline.openLeads}', null),
          const SizedBox(height: 12),
          Text(
            '$newLeads new ${newLeads == 1 ? 'lead' : 'leads'} this period, '
            '$compared ${vs.preposition} ${vs.label}',
            key: const Key('pipeline-new-leads'),
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(color: DaystarColors.ink, height: 1, thickness: 1);
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      key: const Key('dashboard-error'),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Couldn't load the figures", style: text.titleLarge),
          const SizedBox(height: 8),
          Text(message, style: text.bodyMedium),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

/// Figures are still shown, but a refresh failed.
class _StaleNote extends StatelessWidget {
  const _StaleNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.all(12),
      color: DaystarColors.subtle,
      child: Text(
        "Couldn't refresh: $message",
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
