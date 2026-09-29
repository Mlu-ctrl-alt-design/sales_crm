import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../dashboard/dates.dart';
import '../theme/daystar_theme.dart';
import '../theme/money.dart';
import 'lead_screen.dart';
import 'models.dart';
import 'opportunity_screen.dart';
import 'widgets.dart';

enum SalesView { leads, opportunities }

/// The pipeline: leads and opportunities, searchable and filtered.
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key, required this.deps});

  final SalesDeps deps;

  @override
  State<SalesScreen> createState() => SalesScreenState();
}

class SalesScreenState extends State<SalesScreen> {
  SalesView _view = SalesView.leads;
  LeadFilter _leadFilter = LeadFilter.open;
  OpportunityFilter _opportunityFilter = OpportunityFilter.open;
  final _search = TextEditingController();
  Timer? _debounce;

  List<LeadRow>? _leads;
  List<OpportunityRow>? _opportunities;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Fetches the list on screen again, e.g. after something was created.
  Future<void> reload() async {
    final request = ++_request;
    final view = _view;
    final text = _search.text.trim();
    setState(() => _error = null);
    try {
      if (view == SalesView.leads) {
        final rows = await widget.deps.api.listLeads(_leadFilter, text);
        if (!mounted || request != _request) return;
        setState(() => _leads = rows);
      } else {
        final rows = await widget.deps.api.listOpportunities(
          _opportunityFilter,
          text,
        );
        if (!mounted || request != _request) return;
        setState(() => _opportunities = rows);
      }
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(
        () => _error = e is ApiException
            ? e.message
            : "Daystar sent back something the app couldn't read.",
      );
    }
  }

  void _searchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), reload);
  }

  void _showView(SalesView view) {
    if (view == _view) return;
    setState(() => _view = view);
    reload();
  }

  Future<void> _openLead(LeadRow lead) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LeadScreen(deps: widget.deps, name: lead.name),
      ),
    );
    if (mounted) reload();
  }

  Future<void> _openOpportunity(OpportunityRow opportunity) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            OpportunityScreen(deps: widget.deps, name: opportunity.name),
      ),
    );
    if (mounted) reload();
  }

  @override
  Widget build(BuildContext context) {
    final leads = _view == SalesView.leads;
    final rows = leads ? _leads : _opportunities;
    return RefreshIndicator(
      color: DaystarColors.accent,
      onRefresh: reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Room at the end to scroll clear of the + button.
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 112),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SegmentedButton<SalesView>(
              key: const Key('sales-view'),
              segments: const [
                ButtonSegment(value: SalesView.leads, label: Text('Leads')),
                ButtonSegment(
                  value: SalesView.opportunities,
                  label: Text('Opportunities'),
                ),
              ],
              selected: {_view},
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                shape: const RoundedRectangleBorder(),
                side: const BorderSide(color: DaystarColors.ink),
                selectedBackgroundColor: DaystarColors.ink,
                selectedForegroundColor: DaystarColors.surface,
              ),
              onSelectionChanged: (s) => _showView(s.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: TextField(
              key: const Key('sales-search'),
              controller: _search,
              decoration: InputDecoration(
                hintText: leads
                    ? 'Search name, company, email, phone'
                    : 'Search customer or number',
                prefixIcon: const Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onChanged: _searchChanged,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                if (leads)
                  for (final filter in LeadFilter.values)
                    _FilterChip(
                      key: Key('lead-filter-${filter.key}'),
                      label: filter.label,
                      selected: filter == _leadFilter,
                      onSelected: () {
                        setState(() => _leadFilter = filter);
                        reload();
                      },
                    )
                else
                  for (final filter in OpportunityFilter.values)
                    _FilterChip(
                      key: Key('opportunity-filter-${filter.key}'),
                      label: filter.label,
                      selected: filter == _opportunityFilter,
                      onSelected: () {
                        setState(() => _opportunityFilter = filter);
                        reload();
                      },
                    ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_error != null)
            LoadError(message: _error!, onRetry: reload)
          else if (rows == null)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                leads
                    ? 'No leads here. Capture one with the + button.'
                    : 'No opportunities here. Turn a lead into one, or '
                          'start one with the + button.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: DaystarColors.muted),
              ),
            )
          else if (leads)
            for (final lead in _leads!)
              _LeadCard(lead: lead, onTap: () => _openLead(lead))
          else
            for (final opportunity in _opportunities!)
              _OpportunityCard(
                opportunity: opportunity,
                onTap: () => _openOpportunity(opportunity),
              ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        shape: const RoundedRectangleBorder(),
        side: const BorderSide(color: DaystarColors.ink),
        backgroundColor: DaystarColors.surface,
        selectedColor: DaystarColors.ink,
        labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected ? DaystarColors.surface : DaystarColors.ink,
        ),
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

/// A lead as a card: who, where they work, how to reach them.
class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead, required this.onTap});

  final LeadRow lead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      key: Key('lead-${lead.name}'),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: DaystarColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(lead.leadName, style: text.titleMedium)),
                const SizedBox(width: 8),
                StatusTag(lead.status),
              ],
            ),
            if (lead.companyName != null) ...[
              const SizedBox(height: 6),
              IconLine(Icons.apartment_outlined, lead.companyName!),
            ],
            const SizedBox(height: 6),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                if (lead.email != null)
                  IconLine(Icons.mail_outline, lead.email!),
                if (lead.mobile != null)
                  IconLine(Icons.phone_outlined, lead.mobile!),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Eyebrow(
                    [
                      if (lead.created != null)
                        'Added ${dayLabel(lead.created!)}',
                      lead.owner == null ? 'Unassigned' : lead.owner!,
                    ].join(' · '),
                  ),
                ),
                Text(
                  'View lead',
                  style: text.labelLarge?.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.opportunity, required this.onTap});

  final OpportunityRow opportunity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final closing = opportunity.expectedClosing;
    return InkWell(
      key: Key('opportunity-${opportunity.name}'),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: DaystarColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(opportunity.title, style: text.titleMedium),
                ),
                const SizedBox(width: 8),
                StatusTag(opportunity.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              opportunity.amount > 0
                  ? formatMoney(opportunity.amount, opportunity.currency)
                  : 'No value yet',
              style: opportunity.amount > 0
                  ? text.titleLarge
                  : text.bodyMedium?.copyWith(color: DaystarColors.muted),
            ),
            const SizedBox(height: 6),
            Eyebrow(
              [
                opportunity.name,
                if (opportunity.salesStage != null) opportunity.salesStage!,
                if (closing != null) 'Closes ${dayLabel(closing)}',
              ].join(' · '),
            ),
          ],
        ),
      ),
    );
  }
}
