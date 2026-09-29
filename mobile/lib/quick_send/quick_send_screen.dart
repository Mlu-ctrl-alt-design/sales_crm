import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import '../theme/daystar_theme.dart';
import '../theme/money.dart';
import 'draft.dart';
import 'models.dart';
import 'pdf_share.dart';
import 'pickers.dart';
import 'quick_send_api.dart';
import 'receipt_screen.dart';
import 'review_screen.dart';

/// Pick a customer, add items; the total comes from the server as you go.
class QuickSendScreen extends StatefulWidget {
  const QuickSendScreen({
    super.key,
    required this.api,
    required this.draft,
    this.sharePdf = shareViaSheet,
    this.previewDelay = const Duration(milliseconds: 350),
  });

  final QuickSendApi api;
  final QuickSendDraft draft;
  final PdfSharer sharePdf;

  /// Quiet time after an edit before asking the server for totals.
  final Duration previewDelay;

  @override
  State<QuickSendScreen> createState() => _QuickSendScreenState();
}

class _QuickSendScreenState extends State<QuickSendScreen> {
  DocSummary? _preview;
  String? _error;
  bool _loading = false;
  bool _opening = false;
  Timer? _debounce;
  int _request = 0;

  QuickSendDraft get _draft => widget.draft;

  @override
  void initState() {
    super.initState();
    _draft.addListener(_draftChanged);
    if (_draft.isReady) _refresh();
  }

  @override
  void didUpdateWidget(QuickSendScreen old) {
    super.didUpdateWidget(old);
    if (old.draft != widget.draft) {
      old.draft.removeListener(_draftChanged);
      widget.draft.addListener(_draftChanged);
    }
  }

  @override
  void dispose() {
    _draft.removeListener(_draftChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _draftChanged() {
    setState(() {});
    _debounce?.cancel();
    if (!_draft.isReady) {
      _request++;
      setState(() {
        _preview = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(widget.previewDelay, _refresh);
  }

  Future<void> _refresh() async {
    final customer = _draft.customer;
    if (customer == null || _draft.lines.isEmpty) return;
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final preview = await widget.api.preview(
        _draft.kind,
        customer.name,
        _draft.lines,
        opportunity: _draft.opportunity?.name,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _preview = preview;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _chooseCustomer() async {
    final customer = await pickCustomer(context, widget.api);
    if (customer != null) _draft.setCustomer(customer);
  }

  Future<void> _addItem() async {
    final customer = _draft.customer;
    if (customer == null) return;
    final item = await pickItem(context, widget.api, customer.name);
    if (item != null) _draft.addItem(item);
  }

  Future<void> _editRate(int index) async {
    final preview = _preview;
    if (preview == null) return;
    if (!preview.canEditPrices) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            key: Key('price-locked'),
            content: Text(
              '🔒 Prices come from the price list. Ask Mlu to change one.',
            ),
          ),
        );
      return;
    }
    final line = _draft.lines[index];
    final current = _lineFor(line.itemCode)?.rate;
    final result = await showDialog<_RateChoice>(
      context: context,
      builder: (_) => _RateDialog(
        itemName: line.itemName,
        rate: line.rate ?? current,
        listRate: _lineFor(line.itemCode)?.priceListRate,
        currency: preview.currency,
      ),
    );
    if (result != null) _draft.setRate(index, result.rate);
  }

  Future<void> _review() async {
    final preview = _preview;
    if (preview == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReviewScreen(
          api: widget.api,
          draft: _draft,
          preview: preview,
          sharePdf: widget.sharePdf,
        ),
      ),
    );
  }

  Future<void> _sendExisting() async {
    final kind = _draft.kind;
    final listing = await pickDocument(context, widget.api, kind);
    if (listing == null || !mounted) return;
    setState(() => _opening = true);
    try {
      final doc = await widget.api.getDocument(kind, listing.name);
      if (!mounted) return;
      setState(() => _opening = false);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptScreen(
            api: widget.api,
            doc: doc,
            sharePdf: widget.sharePdf,
            justSubmitted: false,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _opening = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _startOver() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start over?'),
        content: const Text('This clears the customer and items.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            key: const Key('confirm-start-over'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start over'),
          ),
        ],
      ),
    );
    if (ok == true) _draft.clear();
  }

  SummaryLine? _lineFor(String itemCode) {
    for (final line in _preview?.lines ?? const <SummaryLine>[]) {
      if (line.itemCode == itemCode) return line;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final customer = _draft.customer;
    final lines = _draft.lines;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<DocKind>(
                      key: const Key('kind-toggle'),
                      segments: [
                        for (final kind in DocKind.values)
                          ButtonSegment(value: kind, label: Text(kind.label)),
                      ],
                      selected: {_draft.kind},
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        shape: const RoundedRectangleBorder(),
                        side: const BorderSide(color: DaystarColors.ink),
                        selectedBackgroundColor: DaystarColors.ink,
                        selectedForegroundColor: DaystarColors.surface,
                      ),
                      onSelectionChanged: (s) => _draft.setKind(s.first),
                    ),
                  ),
                  if (!_draft.isEmpty)
                    IconButton(
                      key: const Key('start-over'),
                      tooltip: 'Start over',
                      onPressed: _startOver,
                      icon: const Icon(Icons.restart_alt),
                    ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('send-existing'),
                  onPressed: _opening ? null : _sendExisting,
                  icon: _opening
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.history),
                  label: Text('Send an earlier ${_draft.kind.noun}'),
                ),
              ),
              const SizedBox(height: 16),
              const Eyebrow('Customer'),
              const SizedBox(height: 8),
              if (customer == null)
                OutlinedButton.icon(
                  key: const Key('choose-customer'),
                  onPressed: _chooseCustomer,
                  icon: const Icon(Icons.person_search_outlined),
                  label: const Text('Choose customer'),
                )
              else
                InkWell(
                  key: const Key('customer-card'),
                  onTap: _chooseCustomer,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: DaystarColors.line),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.customerName,
                                style: text.titleMedium,
                              ),
                              if ((customer.email ?? '').isNotEmpty)
                                Text(customer.email!, style: text.bodySmall),
                            ],
                          ),
                        ),
                        Text(
                          'Change',
                          style: text.labelLarge?.copyWith(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_draft.opportunity case final opportunity?) ...[
                const SizedBox(height: 8),
                Container(
                  key: const Key('draft-opportunity'),
                  padding: const EdgeInsets.only(left: 12),
                  color: DaystarColors.subtle,
                  child: Row(
                    children: [
                      const Icon(Icons.flag_outlined, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'For ${opportunity.title} · ${opportunity.name}',
                          style: text.bodySmall?.copyWith(
                            color: DaystarColors.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('unlink-opportunity'),
                        tooltip: 'Not for this opportunity',
                        visualDensity: VisualDensity.compact,
                        onPressed: _draft.clearOpportunity,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              const Eyebrow('Items'),
              const SizedBox(height: 4),
              for (var i = 0; i < lines.length; i++) ...[
                _LineRow(
                  key: Key('line-${lines[i].itemCode}'),
                  line: lines[i],
                  priced: _lineFor(lines[i].itemCode),
                  currency: _preview?.currency,
                  locked: _preview != null && !_preview!.canEditPrices,
                  onQty: (qty) => _draft.setQty(i, qty),
                  onRate: () => _editRate(i),
                ),
                const Divider(),
              ],
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('add-item'),
                  onPressed: customer == null ? null : _addItem,
                  icon: const Icon(Icons.add),
                  label: Text(
                    customer == null ? 'Choose a customer first' : 'Add item',
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _ErrorNote(message: _error!, onRetry: _refresh),
              ],
            ],
          ),
        ),
        _TotalBar(
          kind: _draft.kind,
          preview: _draft.isReady ? _preview : null,
          loading: _loading,
          enabled:
              _draft.isReady && _preview != null && _error == null && !_loading,
          onReview: _review,
        ),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    super.key,
    required this.line,
    required this.priced,
    required this.currency,
    required this.locked,
    required this.onQty,
    required this.onRate,
  });

  final DraftLine line;
  final SummaryLine? priced;
  final String? currency;
  final bool locked;
  final ValueChanged<double> onQty;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final priced = this.priced;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.itemName, style: text.titleMedium),
                const SizedBox(height: 2),
                InkWell(
                  key: Key('rate-${line.itemCode}'),
                  onTap: onRate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            priced == null
                                ? '…'
                                : '${formatMoney(priced.rate, currency)}'
                                      '${line.uom.isEmpty ? '' : ' / ${line.uom}'}',
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(
                              color: DaystarColors.muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          locked ? Icons.lock_outline : Icons.edit_outlined,
                          size: 14,
                          color: DaystarColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
                if (line.rate != null)
                  const Eyebrow('Own price', color: DaystarColors.accentDeep),
              ],
            ),
          ),
          _QtyStepper(qty: line.qty, onChanged: onQty, id: line.itemCode),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onChanged,
    required this.id,
  });

  final double qty;
  final ValueChanged<double> onChanged;
  final String id;

  Future<void> _type(BuildContext context) async {
    final controller = TextEditingController(text: formatQty(qty));
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quantity'),
        content: TextField(
          key: const Key('qty-input'),
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('qty-save'),
            onPressed: () => Navigator.pop(
              context,
              double.tryParse(controller.text.replaceAll(',', '.')),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null) onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: DaystarColors.ink)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: Key('qty-minus-$id'),
            tooltip: qty <= 1 ? 'Remove' : 'One less',
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(qty - 1),
            icon: Icon(qty <= 1 ? Icons.delete_outline : Icons.remove),
          ),
          InkWell(
            key: Key('qty-$id'),
            onTap: () => _type(context),
            child: SizedBox(
              width: 36,
              child: Text(
                formatQty(qty),
                textAlign: TextAlign.center,
                style: text.titleMedium,
              ),
            ),
          ),
          IconButton(
            key: Key('qty-plus-$id'),
            tooltip: 'One more',
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(qty + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _TotalBar extends StatelessWidget {
  const _TotalBar({
    required this.kind,
    required this.preview,
    required this.loading,
    required this.enabled,
    required this.onReview,
  });

  final DocKind kind;
  final DocSummary? preview;
  final bool loading;
  final bool enabled;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final preview = this.preview;
    return Container(
      decoration: const BoxDecoration(
        color: DaystarColors.surface,
        border: Border(top: BorderSide(color: DaystarColors.ink)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(child: Eyebrow('Total incl. tax')),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(right: 10, bottom: 6),
                  child: SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              Text(
                preview == null
                    ? '—'
                    : formatMoney(preview.total, preview.currency),
                key: const Key('draft-total'),
                style: text.titleLarge?.copyWith(
                  color: loading ? DaystarColors.muted : DaystarColors.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('review'),
            onPressed: enabled ? onReview : null,
            child: Text('Review ${kind.noun}'),
          ),
        ],
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      key: const Key('preview-error'),
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: DaystarColors.moneyOut, width: 3),
        ),
        color: DaystarColors.subtle,
      ),
      child: Row(
        children: [
          Expanded(child: Text(message, style: text.bodyMedium)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _RateChoice {
  const _RateChoice(this.rate);

  /// Null means back to the Price List rate.
  final double? rate;
}

class _RateDialog extends StatefulWidget {
  const _RateDialog({
    required this.itemName,
    required this.rate,
    required this.listRate,
    required this.currency,
  });

  final String itemName;
  final double? rate;
  final double? listRate;
  final String currency;

  @override
  State<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<_RateDialog> {
  late final _controller = TextEditingController(
    text: widget.rate?.toStringAsFixed(2).replaceFirst('.', ',') ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listRate = widget.listRate;
    return AlertDialog(
      title: Text(widget.itemName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('rate-input'),
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
          if (listRate != null) ...[
            const SizedBox(height: 12),
            Text(
              'Price list: ${formatMoney(listRate, widget.currency)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, const _RateChoice(null)),
          child: const Text('Use price list'),
        ),
        TextButton(
          key: const Key('rate-save'),
          onPressed: () {
            final value = double.tryParse(
              _controller.text.replaceAll(' ', '').replaceAll(',', '.'),
            );
            Navigator.pop(context, value == null ? null : _RateChoice(value));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
