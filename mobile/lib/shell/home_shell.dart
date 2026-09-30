import 'package:flutter/material.dart';

import '../auth/auth_repository.dart';
import '../config/env.dart';
import '../forms/form_submit_service.dart';
import '../forms/minimal_form_screen.dart';
import '../forms/mobile_layout_service.dart';
import '../theme/daystar_theme.dart';

enum HeroTab { dashboard, quickSend }

/// The two bespoke hero screens, plus a quick-create button on the
/// screens that aren't already the create flow.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.auth});

  final AuthRepository auth;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  HeroTab _tab = HeroTab.dashboard;

  static const _destinations = {
    HeroTab.dashboard: (
      label: 'Dashboard',
      icon: Icons.insights_outlined,
      selected: Icons.insights,
    ),
    HeroTab.quickSend: (
      label: 'Quick send',
      icon: Icons.send_outlined,
      selected: Icons.send,
    ),
  };

  void _select(HeroTab tab) => setState(() => _tab = tab);

  Future<void> _openQuickCreate() async {
    final choice = await showModalBottomSheet<QuickCreate>(
      context: context,
      builder: (_) => const QuickCreateSheet(),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case QuickCreate.lead:
        await _openMinimalForm(
          doctype: 'CRM Lead',
          mode: 'quick',
          title: 'New lead',
        );
      case QuickCreate.deal:
        await _openMinimalForm(
          doctype: 'CRM Deal',
          mode: 'quick',
          title: 'New deal',
        );
      case QuickCreate.quote:
      case QuickCreate.invoice:
        _select(HeroTab.quickSend);
      case QuickCreate.customer:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'New customers open in the standard form. '
              'Coming in a later build.',
            ),
          ),
        );
    }
  }

  Future<void> _openMinimalForm({
    required String doctype,
    required String mode,
    required String title,
  }) async {
    final layoutService = MobileLayoutService(
      siteUrl: Env.siteUrl,
      accessToken: widget.auth.accessToken,
    );
    final submitService = FormSubmitService(
      siteUrl: Env.siteUrl,
      accessToken: widget.auth.accessToken,
    );
    await Navigator.of(context).push(
      MaterialPageRoute<String>(
        builder: (_) => MinimalFormScreen(
          doctype: doctype,
          mode: mode,
          title: title,
          layoutService: layoutService,
          submitService: submitService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _destinations[_tab]!;
    return Scaffold(
      appBar: AppBar(title: Text(current.label)),
      body: _PlaceholderTab(tab: _tab),
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
          border: Border(top: BorderSide(color: DaystarColors.divider)),
        ),
        child: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (i) => _select(HeroTab.values[i]),
          destinations: [
            for (final tab in HeroTab.values)
              NavigationDestination(
                icon: Icon(_destinations[tab]!.icon),
                selectedIcon: Icon(_destinations[tab]!.selected),
                label: _destinations[tab]!.label,
              ),
          ],
        ),
      ),
    );
  }
}

enum QuickCreate { lead, deal, quote, invoice, customer }

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
          decoration: BoxDecoration(
            color: DaystarColors.brandSoft,
            borderRadius: BorderRadius.circular(DaystarRadius.field),
          ),
          child: Icon(icon, color: DaystarColors.brand, size: 22),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(hint),
        onTap: () => Navigator.of(context).pop(value),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            option(
              QuickCreate.lead,
              Icons.person_outline,
              'New lead',
              'Fields you see are set from the Desk',
            ),
            option(
              QuickCreate.deal,
              Icons.handshake_outlined,
              'New deal',
              'Fields you see are set from the Desk',
            ),
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
            option(
              QuickCreate.customer,
              Icons.person_add_alt_outlined,
              'New customer',
              'Add someone to quote',
            ),
          ],
        ),
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
      HeroTab.quickSend => (
        'Quote or invoice in under 90 seconds',
        'Pick a customer, add items from the price list, review and send.',
      ),
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Text(title, style: text.titleLarge),
        const SizedBox(height: 8),
        Text(body, style: text.bodyLarge?.copyWith(color: DaystarColors.muted)),
        const SizedBox(height: 12),
        Text(
          'Coming soon',
          style: text.labelMedium?.copyWith(color: DaystarColors.brand),
        ),
      ],
    );
  }
}
