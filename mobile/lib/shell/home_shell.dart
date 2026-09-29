import 'package:flutter/material.dart';

import '../auth/key_value_store.dart';
import '../dashboard/dashboard_api.dart';
import '../dashboard/dashboard_screen.dart';
import '../quick_send/draft.dart';
import '../quick_send/models.dart';
import '../quick_send/pdf_share.dart';
import '../quick_send/pickers.dart';
import '../quick_send/quick_send_api.dart';
import '../quick_send/quick_send_screen.dart';
import '../sales/forms.dart';
import '../sales/lead_screen.dart';
import '../sales/models.dart';
import '../sales/opportunity_screen.dart';
import '../sales/sales_api.dart';
import '../sales/sales_screen.dart';
import '../sales/widgets.dart';
import '../theme/daystar_theme.dart';

enum HeroTab { dashboard, sales, assistant, quickSend }

/// The bespoke screens, plus a quick-create button on the screens that
/// aren't already the create flow.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.dashboard,
    required this.quickSend,
    required this.sales,
    required this.drafts,
    this.sharePdf = shareViaSheet,
  });

  final DashboardApi dashboard;
  final SalesApi sales;

  final QuickSendApi quickSend;

  /// Where the quick-send draft is kept between launches.
  final KeyValueStore drafts;
  final PdfSharer sharePdf;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  HeroTab _tab = HeroTab.dashboard;
  QuickSendDraft? _draft;
  final _salesList = GlobalKey<SalesScreenState>();

  late final _salesDeps = SalesDeps(
    api: widget.sales,
    documents: widget.quickSend,
    sharePdf: widget.sharePdf,
    startQuote: _startQuote,
  );

  @override
  void initState() {
    super.initState();
    QuickSendDraft.load(widget.drafts).then((draft) {
      if (mounted) setState(() => _draft = draft);
    });
  }

  @override
  void dispose() {
    _draft?.dispose();
    super.dispose();
  }

  static const _destinations = {
    HeroTab.dashboard: (
      label: 'Dashboard',
      icon: Icons.insights_outlined,
      selected: Icons.insights,
    ),
    HeroTab.sales: (
      label: 'Sales',
      icon: Icons.people_alt_outlined,
      selected: Icons.people_alt,
    ),
    HeroTab.assistant: (
      label: 'Assistant',
      icon: Icons.chat_bubble_outline,
      selected: Icons.chat_bubble,
    ),
    HeroTab.quickSend: (
      label: 'Quick send',
      icon: Icons.send_outlined,
      selected: Icons.send,
    ),
  };

  void _select(HeroTab tab) => setState(() => _tab = tab);

  /// A fresh quote for [customer] on Quick send, from wherever we are.
  /// An unfinished draft for someone else is only replaced if you say so.
  Future<void> _startQuote(
    CustomerOption customer, {
    DraftOpportunity? opportunity,
  }) async {
    final draft = _draft;
    if (draft == null) return;
    final unfinished =
        draft.lines.isNotEmpty ||
        (draft.customer != null && draft.customer!.name != customer.name);
    if (unfinished) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace the unfinished draft?'),
          content: Text(
            'Quick send has a ${draft.kind.noun} in progress'
            '${draft.customer == null ? '' : ' for ${draft.customer!.customerName}'}. '
            'Starting a quote for ${customer.customerName} clears it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep it'),
            ),
            TextButton(
              key: const Key('confirm-replace-draft'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Start the quote'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    draft.startFor(DocKind.quote, customer, opportunity: opportunity);
    Navigator.of(context).popUntil((route) => route.isFirst);
    _select(HeroTab.quickSend);
  }

  Future<void> _openQuickCreate() async {
    final choice = await showModalBottomSheet<QuickCreate>(
      context: context,
      builder: (_) => const QuickCreateSheet(),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case QuickCreate.quote:
        _draft?.setKind(DocKind.quote);
        _select(HeroTab.quickSend);
      case QuickCreate.invoice:
        _draft?.setKind(DocKind.invoice);
        _select(HeroTab.quickSend);
      case QuickCreate.lead:
        await _newLead();
      case QuickCreate.opportunity:
        await _newOpportunity();
      case QuickCreate.customer:
        await _newCustomer();
    }
  }

  Future<void> _newLead() async {
    final lead = await Navigator.of(context).push<LeadDetail>(
      MaterialPageRoute(builder: (_) => NewLeadScreen(api: widget.sales)),
    );
    if (lead == null || !mounted) return;
    _select(HeroTab.sales);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            LeadScreen(deps: _salesDeps, name: lead.lead.name, initial: lead),
      ),
    );
    _salesList.currentState?.reload();
  }

  Future<void> _newOpportunity() async {
    final customer = await pickCustomer(context, widget.quickSend);
    if (customer == null || !mounted) return;
    final opportunity = await createOpportunityFor(
      context,
      _salesDeps,
      customer,
    );
    if (opportunity == null || !mounted) return;
    _select(HeroTab.sales);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OpportunityScreen(
          deps: _salesDeps,
          name: opportunity.opportunity.name,
          initial: opportunity,
        ),
      ),
    );
    _salesList.currentState?.reload();
  }

  Future<void> _newCustomer() async {
    final customer = await Navigator.of(context).push<CustomerOption>(
      MaterialPageRoute(builder: (_) => NewCustomerScreen(api: widget.sales)),
    );
    if (customer == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('customer-added'),
          content: Text('${customer.customerName} added.'),
          action: SnackBarAction(
            label: 'Quote them',
            onPressed: () => _startQuote(customer),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final current = _destinations[_tab]!;
    return Scaffold(
      appBar: AppBar(title: Text(current.label)),
      body: switch (_tab) {
        HeroTab.quickSend =>
          _draft == null
              ? const Center(child: CircularProgressIndicator())
              : QuickSendScreen(
                  api: widget.quickSend,
                  draft: _draft!,
                  sharePdf: widget.sharePdf,
                ),
        HeroTab.dashboard => DashboardScreen(api: widget.dashboard),
        HeroTab.sales => SalesScreen(key: _salesList, deps: _salesDeps),
        _ => _PlaceholderTab(tab: _tab),
      },
      floatingActionButton: _tab == HeroTab.quickSend
          ? null
          : FloatingActionButton(
              key: const Key('quick-create'),
              tooltip: 'Create',
              onPressed: _openQuickCreate,
              child: const Icon(Icons.add, size: 28),
            ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: DaystarColors.ink)),
        ),
        child: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (i) => _select(HeroTab.values[i]),
          destinations: [
            for (final tab in HeroTab.values)
              NavigationDestination(
                icon: Icon(_destinations[tab]!.icon),
                selectedIcon: Icon(_destinations[tab]!.selected),
                label: _destinations[tab]!.label.toUpperCase(),
              ),
          ],
        ),
      ),
    );
  }
}

enum QuickCreate { lead, opportunity, customer, quote, invoice }

class QuickCreateSheet extends StatelessWidget {
  const QuickCreateSheet({super.key});

  @override
  Widget build(BuildContext context) {
    Widget option(QuickCreate value, IconData icon, String title, String hint) {
      return ListTile(
        key: Key('create-${value.name}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        leading: Container(
          width: 40,
          height: 40,
          color: DaystarColors.subtle,
          child: Icon(icon, color: DaystarColors.brand, size: 22),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(hint),
        onTap: () => Navigator.of(context).pop(value),
      );
    }

    // Scrolls when five options don't fit (small phones, landscape).
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            option(
              QuickCreate.lead,
              Icons.person_search_outlined,
              'New lead',
              'Someone who asked about Daystar',
            ),
            option(
              QuickCreate.opportunity,
              Icons.flag_outlined,
              'New opportunity',
              'A deal with an existing customer',
            ),
            option(
              QuickCreate.customer,
              Icons.person_add_alt_outlined,
              'New customer',
              'Add someone to quote',
            ),
            const Divider(indent: 24, endIndent: 24),
            option(
              QuickCreate.quote,
              Icons.request_quote_outlined,
              'New quote',
              'Priced from the price list',
            ),
            option(
              QuickCreate.invoice,
              Icons.receipt_long_outlined,
              'New invoice',
              'Submit and send in one go',
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.tab});

  final HeroTab tab;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (title, body) = switch (tab) {
      HeroTab.dashboard => (
        'Sales health, at a glance',
        'Invoiced profit, money in and out, receivables and your pipeline '
            'will show here.',
      ),
      HeroTab.assistant => (
        'Ask about the business',
        'Questions are answered from ERPNext. Anything that changes a '
            'record waits for your tap.',
      ),
      HeroTab.quickSend || HeroTab.sales => ('', ''),
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Text(title, style: text.titleLarge),
        const SizedBox(height: 8),
        Text(body, style: text.bodyLarge?.copyWith(color: DaystarColors.muted)),
        const SizedBox(height: 12),
        const Eyebrow('Coming soon', color: DaystarColors.accentDeep),
      ],
    );
  }
}
