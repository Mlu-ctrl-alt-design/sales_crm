import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../dashboard/dates.dart';
import '../theme/daystar_theme.dart';
import '../theme/money.dart';
import 'models.dart';
import 'opportunity_screen.dart';
import 'widgets.dart';

/// One lead: who they are, where they are in the process, and the next step.
class LeadScreen extends StatefulWidget {
  const LeadScreen({
    super.key,
    required this.deps,
    required this.name,
    this.initial,
  });

  final SalesDeps deps;
  final String name;

  /// Shown straight away, e.g. just after capturing the lead.
  final LeadDetail? initial;

  @override
  State<LeadScreen> createState() => _LeadScreenState();
}

class _LeadScreenState extends State<LeadScreen> {
  late LeadDetail? _lead = widget.initial;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (_lead == null) _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final lead = await widget.deps.api.getLead(widget.name);
      if (mounted) setState(() => _lead = lead);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// Runs an action with the buttons disabled; errors show as a snackbar.
  Future<T?> _run<T>(Future<T> Function() action) async {
    setState(() => _busy = true);
    try {
      return await action();
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message);
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createOpportunity(LeadDetail lead) async {
    final values = await showOpportunitySheet(
      context,
      title: 'Opportunity with ${lead.lead.leadName}',
    );
    if (values == null || !mounted) return;
    final opportunity = await _run(
      () => widget.deps.api.leadToOpportunity(
        lead.lead.name,
        amount: values.amount,
        expectedClosing: values.closing,
      ),
    );
    if (opportunity == null || !mounted) return;
    await _openOpportunity(opportunity.opportunity.name, opportunity);
  }

  Future<void> _openOpportunity(
    String name, [
    OpportunityDetail? initial,
  ]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            OpportunityScreen(deps: widget.deps, name: name, initial: initial),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _makeCustomer(LeadDetail lead) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make customer?'),
        content: Text(
          'Adds ${lead.lead.companyName ?? lead.lead.leadName} as a customer, '
          'with their contact details, and marks the lead converted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm-make-customer'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Make customer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final customer = await _run(
      () => widget.deps.api.makeCustomer(lead: lead.lead.name),
    );
    if (customer == null || !mounted) return;
    showMessage(context, '${customer.customerName} is now a customer.');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final lead = _lead;
    return Scaffold(
      appBar: AppBar(title: const Text('Lead')),
      body: lead == null
          ? (_error == null
                ? const Center(child: CircularProgressIndicator())
                : LoadError(message: _error!, onRetry: _load))
          : RefreshIndicator(
              color: DaystarColors.accent,
              onRefresh: _load,
              child: _body(context, lead),
            ),
    );
  }

  Widget _body(BuildContext context, LeadDetail detail) {
    final text = Theme.of(context).textTheme;
    final lead = detail.lead;
    final customer = detail.customer;
    final hasOpportunity = detail.opportunities.isNotEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      children: [
        Container(
          key: const Key('lead-header'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DaystarColors.subtle,
            border: Border.all(color: DaystarColors.ink),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(lead.leadName, style: text.titleLarge)),
                  StatusTag(lead.status),
                ],
              ),
              if (lead.companyName != null) ...[
                const SizedBox(height: 8),
                IconLine(Icons.apartment_outlined, lead.companyName!),
              ],
              if (lead.email != null) ...[
                const SizedBox(height: 6),
                IconLine(Icons.mail_outline, lead.email!),
              ],
              if (lead.mobile != null) ...[
                const SizedBox(height: 6),
                IconLine(Icons.phone_outlined, lead.mobile!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        StageTrack(stage: detail.stage),
        const SizedBox(height: 20),
        if (!hasOpportunity && detail.canConvert)
          FilledButton.icon(
            key: const Key('create-opportunity'),
            onPressed: _busy ? null : () => _createOpportunity(detail),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Create opportunity'),
          )
        else if (hasOpportunity)
          FilledButton.icon(
            key: const Key('open-opportunity'),
            onPressed: _busy
                ? null
                : () => _openOpportunity(detail.opportunities.first.name),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Open opportunity'),
          ),
        const SizedBox(height: 10),
        if (customer == null)
          OutlinedButton.icon(
            key: const Key('make-customer'),
            onPressed: _busy ? null : () => _makeCustomer(detail),
            icon: const Icon(Icons.person_add_alt_outlined),
            label: const Text('Make customer'),
          )
        else
          OutlinedButton.icon(
            key: const Key('quote-customer'),
            onPressed: _busy ? null : () => widget.deps.startQuote(customer),
            icon: const Icon(Icons.request_quote_outlined),
            label: Text('Quote ${customer.customerName}'),
          ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: 32),
        const Eyebrow('Details'),
        const Divider(height: 20),
        DetailField('Contact note', detail.notes),
        DetailField('Customer', customer?.customerName),
        DetailField('First name', detail.firstName),
        DetailField('Last name', detail.lastName),
        DetailField('Telephone', detail.phone),
        DetailField('Website', detail.website),
        DetailField('City', detail.city),
        DetailField('Lead source', detail.source),
        DetailField('Owner', lead.owner ?? 'Unassigned'),
        DetailField(
          'Added',
          lead.created == null ? null : dayLabel(lead.created!),
        ),
        DetailField('Lead number', lead.name),
        if (hasOpportunity) ...[
          const SizedBox(height: 16),
          const Eyebrow('Opportunities'),
          const Divider(height: 20),
          for (final opportunity in detail.opportunities)
            ListTile(
              key: Key('lead-opportunity-${opportunity.name}'),
              contentPadding: EdgeInsets.zero,
              title: Text(opportunity.title, style: text.titleMedium),
              subtitle: Text(
                '${opportunity.name} · ${opportunity.status}',
                style: text.bodySmall,
              ),
              trailing: Text(
                opportunity.amount > 0
                    ? formatMoney(opportunity.amount, opportunity.currency)
                    : '',
                style: text.titleMedium,
              ),
              onTap: () => _openOpportunity(opportunity.name),
            ),
        ],
      ],
    );
  }
}
