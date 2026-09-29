import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme/daystar_theme.dart';
import '../theme/money.dart';
import 'draft.dart';
import 'models.dart';
import 'pdf_share.dart';
import 'quick_send_api.dart';
import 'receipt_screen.dart';

/// The server's preview, then one tap to submit.
///
/// A failed submit keeps the draft and retries with the same key, so the
/// document is never created twice even if the first answer was lost.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.api,
    required this.draft,
    required this.preview,
    required this.sharePdf,
  });

  final QuickSendApi api;
  final QuickSendDraft draft;
  final DocSummary preview;
  final PdfSharer sharePdf;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _submitting = false;
  ApiException? _error;

  Future<void> _submit() async {
    final draft = widget.draft;
    final customer = draft.customer;
    if (customer == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final submitted = await widget.api.submit(
        draft.kind,
        customer.name,
        draft.lines,
        draft.key,
        opportunity: draft.opportunity?.name,
      );
      draft.clear();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptScreen(
            api: widget.api,
            doc: submitted,
            sharePdf: widget.sharePdf,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final doc = widget.preview;
    final noun = doc.kind.noun;
    return Scaffold(
      appBar: AppBar(title: Text('Review $noun')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              children: [
                const Eyebrow('Customer'),
                const SizedBox(height: 6),
                Text(doc.customerName, style: text.titleLarge),
                const SizedBox(height: 28),
                const Eyebrow('Items'),
                const SizedBox(height: 4),
                for (final line in doc.lines) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(line.itemName, style: text.titleMedium),
                              Text(
                                '${formatQty(line.qty)} × '
                                '${formatMoney(line.rate, doc.currency)}',
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatMoney(line.amount, doc.currency),
                          style: text.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                ],
                const SizedBox(height: 12),
                _AmountRow('Subtotal', doc.netTotal, doc.currency),
                for (final tax in doc.taxes)
                  _AmountRow(tax.description, tax.amount, doc.currency),
                const SizedBox(height: 8),
                const Divider(color: DaystarColors.ink),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(child: Eyebrow('Total')),
                    Text(
                      formatMoney(doc.total, doc.currency),
                      key: const Key('review-total'),
                      style: text.displaySmall?.copyWith(fontSize: 30),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 24),
                  _SubmitError(error: _error!, noun: noun),
                ],
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: DaystarColors.ink)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
            child: SafeArea(
              top: false,
              child: FilledButton(
                key: const Key('submit'),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: DaystarColors.muted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Submitting $noun…',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Text(_error == null ? 'Submit $noun' : 'Try again'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(this.label, this.amount, this.currency);

  final String label;
  final double amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: DaystarColors.muted),
            ),
          ),
          Text(formatMoney(amount, currency), style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _SubmitError extends StatelessWidget {
  const _SubmitError({required this.error, required this.noun});

  final ApiException error;
  final String noun;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final message = error.kind == ApiErrorKind.offline
        ? "Couldn't confirm the $noun was submitted. Your entries are kept; "
              "try again and it won't be created twice."
        : error.message;
    return Container(
      key: const Key('submit-error'),
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: DaystarColors.moneyOut, width: 3),
        ),
        color: DaystarColors.subtle,
      ),
      child: Text(message, style: text.bodyMedium),
    );
  }
}
