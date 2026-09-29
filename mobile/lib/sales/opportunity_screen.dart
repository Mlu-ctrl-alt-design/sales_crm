import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../dashboard/dates.dart';
import '../quick_send/draft.dart';
import '../quick_send/models.dart';
import '../theme/daystar_theme.dart';
import '../theme/money.dart';
import 'models.dart';
import 'widgets.dart';

/// One opportunity: its value, its quotes, and "Create quote".
class OpportunityScreen extends StatefulWidget {
  const OpportunityScreen({
    super.key,
    required this.deps,
    required this.name,
    this.initial,
  });

  final SalesDeps deps;
  final String name;
  final OpportunityDetail? initial;

  @override
  State<OpportunityScreen> createState() => _OpportunityScreenState();
}

class _OpportunityScreenState extends State<OpportunityScreen> {
  late OpportunityDetail? _detail = widget.initial;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (_detail == null) _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final detail = await widget.deps.api.getOpportunity(widget.name);
      if (mounted) setState(() => _detail = detail);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// Quotes go to customers, so a lead is made one first (after asking).
  Future<void> _createQuote(OpportunityDetail detail) async {
    final opportunity = detail.opportunity;
    var customer = detail.customer;
    if (customer == null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Make them a customer?'),
          content: Text(
            'Quotes go to customers. This adds ${opportunity.title} as a '
            'customer from the lead, then starts the quote.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              key: const Key('confirm-make-customer'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Make customer and quote'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      setState(() => _busy = true);
      try {
        customer = await widget.deps.api.makeCustomer(
          opportunity: opportunity.name,
        );
      } on ApiException catch (e) {
        if (mounted) showMessage(context, e.message);
        return;
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      if (!mounted) return;
    }
    await widget.deps.startQuote(
      customer,
      opportunity: DraftOpportunity(
        name: opportunity.name,
        title: opportunity.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      appBar: AppBar(title: const Text('Opportunity')),
      body: detail == null
          ? (_error == null
                ? const Center(child: CircularProgressIndicator())
                : LoadError(message: _error!, onRetry: _load))
          : RefreshIndicator(
              color: DaystarColors.accent,
              onRefresh: _load,
              child: _body(context, detail),
            ),
    );
  }

  Widget _body(BuildContext context, OpportunityDetail detail) {
    final text = Theme.of(context).textTheme;
    final opportunity = detail.opportunity;
    final closing = opportunity.expectedClosing;
    final open = const {
      'Open',
      'Replied',
      'Quotation',
    }.contains(opportunity.status);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      children: [
        Row(
          children: [
            Expanded(child: Eyebrow(opportunity.name)),
            StatusTag(opportunity.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          opportunity.title,
          key: const Key('opportunity-title'),
          style: text.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          opportunity.amount > 0
              ? formatMoney(opportunity.amount, opportunity.currency)
              : 'No value yet',
          style: opportunity.amount > 0
              ? text.displaySmall?.copyWith(fontSize: 32)
              : text.bodyLarge?.copyWith(color: DaystarColors.muted),
        ),
        const SizedBox(height: 20),
        StageTrack(stage: detail.stage),
        const SizedBox(height: 20),
        if (open)
          FilledButton.icon(
            key: const Key('create-quote'),
            onPressed: _busy ? null : () => _createQuote(detail),
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DaystarColors.muted,
                    ),
                  )
                : const Icon(Icons.request_quote_outlined),
            label: Text(detail.quotes.isEmpty ? 'Create quote' : 'New quote'),
          ),
        if (detail.quotes.isNotEmpty) ...[
          const SizedBox(height: 32),
          const Eyebrow('Quotes'),
          const Divider(height: 20),
          for (final quote in detail.quotes)
            _QuoteTile(
              quote: quote,
              onTap: quote.submitted
                  ? () async {
                      await widget.deps.openQuote(context, quote.name);
                      if (mounted) _load();
                    }
                  : null,
            ),
          const SizedBox(height: 4),
          Text(
            'Open a submitted quote to send it again or make the invoice.',
            style: text.bodySmall,
          ),
        ],
        const SizedBox(height: 32),
        const Eyebrow('Details'),
        const Divider(height: 20),
        DetailField(
          'Customer',
          detail.customer?.customerName ??
              '${opportunity.title} (still a lead)',
        ),
        DetailField('Contact email', detail.contactEmail),
        DetailField('Contact mobile', detail.contactMobile),
        DetailField('Sales stage', opportunity.salesStage),
        DetailField(
          'Expected to close',
          closing == null ? null : dayLabel(closing),
        ),
        DetailField('Owner', opportunity.owner),
        DetailField('Note', detail.notes),
        DetailField('From', '${opportunity.from} ${opportunity.partyName}'),
      ],
    );
  }
}

class _QuoteTile extends StatelessWidget {
  const _QuoteTile({required this.quote, required this.onTap});

  final QuoteRow quote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListTile(
      key: Key('quote-${quote.name}'),
      contentPadding: EdgeInsets.zero,
      title: Text(quote.name, style: text.titleMedium),
      subtitle: Text(
        [
          if (quote.date != null) dayLabel(quote.date!),
          quote.submitted ? quote.status : 'Draft, finish it in Desk',
        ].join(' · '),
        style: text.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatMoney(quote.total, quote.currency),
            style: text.titleMedium,
          ),
          if (onTap != null) const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Starts an opportunity with an existing customer: value and closing
/// date, then opens it. Null if cancelled or refused.
Future<OpportunityDetail?> createOpportunityFor(
  BuildContext context,
  SalesDeps deps,
  CustomerOption customer,
) async {
  final values = await showOpportunitySheet(
    context,
    title: 'Opportunity with ${customer.customerName}',
  );
  if (values == null || !context.mounted) return null;
  try {
    return await deps.api.createOpportunity(
      customer.name,
      amount: values.amount,
      expectedClosing: values.closing,
    );
  } on ApiException catch (e) {
    if (context.mounted) showMessage(context, e.message);
    return null;
  }
}
