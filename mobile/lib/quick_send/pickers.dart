import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../dashboard/dates.dart';
import '../theme/daystar_theme.dart';
import '../theme/money.dart';
import 'models.dart';
import 'quick_send_api.dart';

Future<CustomerOption?> pickCustomer(BuildContext context, QuickSendApi api) {
  return _showSearch<CustomerOption>(
    context,
    title: 'Choose customer',
    hint: 'Name, email or phone',
    search: api.searchCustomers,
    empty: 'No customers match. New customers are added in Desk for now.',
    tile: (context, customer) => ListTile(
      key: Key('customer-${customer.name}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(
        customer.customerName,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: _subtitle(customer.email, customer.mobile),
    ),
  );
}

Future<ItemOption?> pickItem(
  BuildContext context,
  QuickSendApi api,
  String customer,
) {
  String? currency;
  return _showSearch<ItemOption>(
    context,
    title: 'Add item',
    hint: 'Item name or code',
    search: (text) async {
      final result = await api.searchItems(customer, text);
      currency = result.currency;
      return result.items;
    },
    empty: 'No sellable items match.',
    tile: (context, item) {
      final text = Theme.of(context).textTheme;
      return ListTile(
        key: Key('item-${item.itemCode}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(item.itemName, style: text.titleMedium),
        subtitle: Text(
          [item.itemCode, if (item.uom.isNotEmpty) item.uom].join(' · '),
          style: text.bodySmall,
        ),
        trailing: Text(
          item.rate == null ? 'No price' : formatMoney(item.rate!, currency),
          style: item.rate == null
              ? text.bodySmall
              : text.titleMedium?.copyWith(fontFamily: DaystarFonts.serif),
        ),
      );
    },
  );
}

Future<DocListing?> pickDocument(
  BuildContext context,
  QuickSendApi api,
  DocKind kind,
) {
  return _showSearch<DocListing>(
    context,
    title: 'Send a ${kind.noun} again',
    hint: 'Number or customer',
    search: (text) => api.searchDocuments(kind, text),
    empty: 'No submitted ${kind.noun}s match.',
    tile: (context, doc) {
      final text = Theme.of(context).textTheme;
      return ListTile(
        key: Key('doc-${doc.name}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(doc.customerName, style: text.titleMedium),
        subtitle: Text(
          [
            doc.name,
            if (doc.date != null) dayLabel(doc.date!),
            if ((doc.status ?? '').isNotEmpty) doc.status!,
          ].join(' · '),
          style: text.bodySmall,
        ),
        trailing: Text(
          formatMoney(doc.total, doc.currency),
          style: text.titleMedium?.copyWith(fontFamily: DaystarFonts.serif),
        ),
      );
    },
  );
}

Widget? _subtitle(String? a, String? b) {
  final parts = [a, b].whereType<String>().where((s) => s.isNotEmpty);
  return parts.isEmpty ? null : Text(parts.join(' · '));
}

Future<T?> _showSearch<T>(
  BuildContext context, {
  required String title,
  required String hint,
  required Future<List<T>> Function(String text) search,
  required String empty,
  required Widget Function(BuildContext context, T option) tile,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.92,
      child: _SearchSheet<T>(
        title: title,
        hint: hint,
        search: search,
        empty: empty,
        tile: tile,
      ),
    ),
  );
}

class _SearchSheet<T> extends StatefulWidget {
  const _SearchSheet({
    required this.title,
    required this.hint,
    required this.search,
    required this.empty,
    required this.tile,
  });

  final String title;
  final String hint;
  final Future<List<T>> Function(String text) search;
  final String empty;
  final Widget Function(BuildContext context, T option) tile;

  @override
  State<_SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<_SearchSheet<T>> {
  Timer? _debounce;
  List<T>? _results;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _run('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _changed(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(text));
  }

  Future<void> _run(String text) async {
    final request = ++_request;
    setState(() => _error = null);
    try {
      final results = await widget.search(text.trim());
      if (!mounted || request != _request) return;
      setState(() => _results = results);
    } on ApiException catch (e) {
      if (!mounted || request != _request) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final results = _results;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(widget.title, style: text.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            key: const Key('picker-search'),
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.search),
            ),
            textInputAction: TextInputAction.search,
            onChanged: _changed,
          ),
        ),
        const SizedBox(height: 8),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              style: text.bodyMedium?.copyWith(color: DaystarColors.moneyOut),
            ),
          )
        else if (results == null)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              widget.empty,
              style: text.bodyMedium?.copyWith(color: DaystarColors.muted),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: results.length,
              separatorBuilder: (_, _) => const Divider(indent: 24),
              itemBuilder: (context, i) => InkWell(
                onTap: () => Navigator.of(context).pop(results[i]),
                child: widget.tile(context, results[i]),
              ),
            ),
          ),
      ],
    );
  }
}
