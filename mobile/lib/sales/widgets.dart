import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import '../dashboard/dates.dart';
import '../quick_send/draft.dart';
import '../quick_send/models.dart';
import '../quick_send/pdf_share.dart';
import '../quick_send/quick_send_api.dart';
import '../quick_send/receipt_screen.dart';
import '../theme/daystar_theme.dart';
import 'models.dart';
import 'sales_api.dart';

/// What the sales screens need from the rest of the app.
class SalesDeps {
  const SalesDeps({
    required this.api,
    required this.documents,
    required this.sharePdf,
    required this.startQuote,
  });

  final SalesApi api;

  /// Quotes and invoices, as on the Quick send tab.
  final QuickSendApi documents;
  final PdfSharer sharePdf;

  /// Opens Quick send with a fresh quote for [customer].
  final Future<void> Function(
    CustomerOption customer, {
    DraftOpportunity? opportunity,
  })
  startQuote;

  /// A submitted quote, to send again or make into an invoice.
  Future<void> openQuote(BuildContext context, String name) async {
    try {
      final doc = await documents.getDocument(DocKind.quote, name);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptScreen(
            api: documents,
            doc: doc,
            sharePdf: sharePdf,
            justSubmitted: false,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (context.mounted) showMessage(context, e.message);
    }
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Lead → Opportunity → Quote → Invoice, with [stage] highlighted.
class StageTrack extends StatelessWidget {
  const StageTrack({super.key, required this.stage});

  final SalesStage stage;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      key: const Key('stage-track'),
      children: [
        for (final step in SalesStage.values) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  color: step.index < stage.index
                      ? DaystarColors.ink
                      : step == stage
                      ? DaystarColors.accent
                      : DaystarColors.line,
                ),
                const SizedBox(height: 6),
                Text(
                  step.label.toUpperCase(),
                  style: text.labelSmall?.copyWith(
                    fontSize: 9.5,
                    letterSpacing: 1,
                    color: step.index <= stage.index
                        ? DaystarColors.ink
                        : DaystarColors.muted,
                    fontWeight: step == stage ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          ),
          if (step != SalesStage.values.last) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

/// An icon and a line of text, as on the lead cards.
class IconLine extends StatelessWidget {
  const IconLine(this.icon, this.text, {super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: DaystarColors.muted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// A label over its value, for detail sections.
class DetailField extends StatelessWidget {
  const DetailField(this.label, this.value, {super.key});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(label),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// ERPNext status as a small mono tag.
class StatusTag extends StatelessWidget {
  const StatusTag(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final dead = const {
      'Lost',
      'Closed',
      'Do Not Contact',
      'Lost Quotation',
    }.contains(status);
    final won = const {'Converted', 'Ordered'}.contains(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: won
              ? DaystarColors.moneyIn
              : dead
              ? DaystarColors.muted
              : DaystarColors.ink,
        ),
      ),
      child: Eyebrow(
        status,
        color: won ? DaystarColors.moneyIn : DaystarColors.ink,
      ),
    );
  }
}

/// A failed load, with Try again.
class LoadError extends StatelessWidget {
  const LoadError({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      key: const Key('sales-error'),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Couldn't load this", style: text.titleLarge),
          const SizedBox(height: 8),
          Text(message, style: text.bodyMedium),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

/// Value and expected closing for a new opportunity; null if cancelled.
Future<({double? amount, DateTime? closing})?> showOpportunitySheet(
  BuildContext context, {
  required String title,
  DateTime Function() now = DateTime.now,
}) {
  return showModalBottomSheet<({double? amount, DateTime? closing})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _OpportunitySheet(title: title, now: now),
  );
}

class _OpportunitySheet extends StatefulWidget {
  const _OpportunitySheet({required this.title, required this.now});

  final String title;
  final DateTime Function() now;

  @override
  State<_OpportunitySheet> createState() => _OpportunitySheetState();
}

class _OpportunitySheetState extends State<_OpportunitySheet> {
  final _amount = TextEditingController();
  DateTime? _closing;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickClosing() async {
    final today = widget.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _closing ?? today.add(const Duration(days: 30)),
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 3),
    );
    if (picked != null) setState(() => _closing = picked);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Both are optional; you can fill them in later in Desk.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('opportunity-amount'),
            controller: _amount,
            decoration: const InputDecoration(
              labelText: 'Deal value (R)',
              prefixText: 'R ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            key: const Key('opportunity-closing'),
            onTap: _pickClosing,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Expected to close'),
              child: Text(
                _closing == null ? 'Choose a date' : dayLabel(_closing!),
                style: text.bodyLarge?.copyWith(
                  color: _closing == null ? DaystarColors.muted : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('opportunity-save'),
            onPressed: () {
              final amount = double.tryParse(
                _amount.text.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.'),
              );
              Navigator.pop(context, (amount: amount, closing: _closing));
            },
            child: const Text('Create opportunity'),
          ),
        ],
      ),
    );
  }
}
