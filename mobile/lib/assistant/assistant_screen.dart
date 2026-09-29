import 'package:flutter/material.dart';

import '../quick_send/models.dart';
import '../quick_send/pdf_share.dart';
import '../quick_send/quick_send_api.dart';
import '../quick_send/receipt_screen.dart';
import '../theme/daystar_theme.dart';
import '../theme/money.dart';
import 'conversation.dart';

/// Ask about the business; anything that changes a record waits for a tap.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({
    super.key,
    required this.conversation,
    required this.documents,
    required this.sharePdf,
  });

  final Conversation conversation;

  /// To open a document the assistant made, to send it.
  final QuickSendApi documents;
  final PdfSharer sharePdf;

  static const suggestions = [
    'How are sales this month?',
    'Who owes us the most?',
    'Find the latest quote for a customer',
    'Draft a quote for a customer',
  ];

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  Conversation get _chat => widget.conversation;

  @override
  void initState() {
    super.initState();
    _chat.addListener(_changed);
    _input.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(AssistantScreen old) {
    super.didUpdateWidget(old);
    if (old.conversation != widget.conversation) {
      old.conversation.removeListener(_changed);
      widget.conversation.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _chat.removeListener(_changed);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _changed() {
    setState(() {});
    // Keep the newest turn in view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send([String? text]) {
    final message = (text ?? _input.text).trim();
    if (message.isEmpty || _chat.thinking) return;
    _input.clear();
    _chat.send(message);
  }

  Future<void> _open(DocSummary doc) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ReceiptScreen(
        api: widget.documents,
        doc: doc,
        sharePdf: widget.sharePdf,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final entries = _chat.entries;
    return Column(
      children: [
        Expanded(
          child: _chat.isEmpty
              ? _Welcome(onPick: _send)
              : ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        key: const Key('new-chat'),
                        onPressed: _chat.thinking ? null : _chat.clear,
                        icon: const Icon(Icons.add_comment_outlined, size: 18),
                        label: const Text('New chat'),
                      ),
                    ),
                    for (final entry in entries)
                      switch (entry) {
                        UserEntry() => _Bubble(text: entry.text, mine: true),
                        AssistantEntry() => _Bubble(
                          text: entry.text,
                          mine: false,
                        ),
                        ErrorEntry() => _ErrorBubble(
                          entry: entry,
                          onRetry: entry.retry == null
                              ? null
                              : () => _chat.retry(entry),
                        ),
                        ActionEntry() => ActionCard(
                          entry: entry,
                          onConfirm: () => _chat.confirm(entry),
                          onCancel: () => _chat.cancel(entry),
                          onOpen: _open,
                        ),
                      },
                    if (_chat.thinking) const _Thinking(),
                  ],
                ),
        ),
        _Composer(
          controller: _input,
          busy: _chat.thinking,
          onSend: () => _send(),
        ),
      ],
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Text('Ask about the business', style: text.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Answers come from ERPNext, as you. Anything that creates or sends '
          'a document waits for your tap.',
          style: text.bodyLarge?.copyWith(color: DaystarColors.muted),
        ),
        const SizedBox(height: 24),
        const Eyebrow('Try'),
        const SizedBox(height: 8),
        for (final suggestion in AssistantScreen.suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              key: Key('suggestion-${suggestion.hashCode}'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size.fromHeight(44),
                side: const BorderSide(color: DaystarColors.line),
                textStyle: text.bodyMedium,
              ),
              onPressed: () => onPick(suggestion),
              child: Text(suggestion),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.mine});

  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? DaystarColors.ink : DaystarColors.subtle,
        ),
        child: SelectableText(
          text,
          style: style?.copyWith(
            color: mine ? DaystarColors.surface : DaystarColors.ink,
          ),
        ),
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({required this.entry, required this.onRetry});

  final ErrorEntry entry;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      key: const Key('assistant-error'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: const BoxDecoration(
        color: DaystarColors.subtle,
        border: Border(
          left: BorderSide(color: DaystarColors.moneyOut, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text(entry.text, style: text.bodyMedium)),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      key: Key('assistant-thinking'),
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Eyebrow('Looking it up'),
        ],
      ),
    );
  }
}

/// A proposed write: what it will do, then Confirm or Cancel.
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.entry,
    required this.onConfirm,
    required this.onCancel,
    required this.onOpen,
  });

  final ActionEntry entry;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final ValueChanged<DocSummary> onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final action = entry.action;
    final state = entry.state;
    final open = state == ActionState.waiting || state == ActionState.failed;
    return Container(
      key: Key('action-${action.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: state == ActionState.done
              ? DaystarColors.moneyIn
              : DaystarColors.ink,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Eyebrow(
            switch (state) {
              ActionState.done => 'Done',
              ActionState.cancelled => 'Cancelled',
              _ => 'Needs your OK',
            },
            color: state == ActionState.done
                ? DaystarColors.moneyIn
                : state == ActionState.cancelled
                ? DaystarColors.muted
                : DaystarColors.accentDeep,
          ),
          const SizedBox(height: 8),
          if (action.isSubmit) _SubmitPreview(entry: entry),
          if (action.isEmail) _EmailPreview(entry: entry),
          if (!action.isSubmit && !action.isEmail)
            Text(action.toolName, style: text.titleMedium),
          if (entry.error != null) ...[
            const SizedBox(height: 10),
            Text(
              entry.error!,
              key: const Key('action-error'),
              style: text.bodyMedium?.copyWith(color: DaystarColors.moneyOut),
            ),
          ],
          if (open || state == ActionState.running) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('action-cancel'),
                    onPressed: open ? onCancel : null,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const Key('action-confirm'),
                    onPressed: open ? onConfirm : null,
                    child: Text(
                      state == ActionState.running
                          ? 'Working…'
                          : state == ActionState.failed
                          ? 'Try again'
                          : 'Confirm',
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (state == ActionState.done && action.isSubmit)
            _OpenDone(result: entry.result, onOpen: onOpen),
        ],
      ),
    );
  }
}

class _SubmitPreview extends StatelessWidget {
  const _SubmitPreview({required this.entry});

  final ActionEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final args = entry.action.arguments;
    final doc = _summary(entry.action.preview);
    final kind = DocKind.fromDoctype('${args['doctype'] ?? doc?.kind.doctype}');
    if (doc == null) {
      // No preview (e.g. it failed to price): say what was asked for.
      final items = args['items'];
      return Text(
        'Submit a ${kind.noun} for ${args['customer'] ?? 'a customer'}'
        '${items is List ? ' with ${items.length} item${items.length == 1 ? '' : 's'}' : ''}.',
        style: text.titleMedium,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Submit ${kind.noun} for ${doc.customerName}',
          style: text.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final line in doc.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatQty(line.qty)} × ${line.itemName}',
                    style: text.bodyMedium,
                  ),
                ),
                Text(
                  formatMoney(line.amount, doc.currency),
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
        const Divider(height: 16),
        Row(
          children: [
            const Expanded(child: Eyebrow('Total incl. tax')),
            Text(
              formatMoney(doc.total, doc.currency),
              key: const Key('action-total'),
              style: text.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Submitting makes it final in ERPNext.', style: text.bodySmall),
      ],
    );
  }
}

class _EmailPreview extends StatelessWidget {
  const _EmailPreview({required this.entry});

  final ActionEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final info = entry.action.preview ?? entry.action.arguments;
    final to = info['recipients'];
    final recipients = to is List ? to.join(', ') : '${to ?? ''}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email ${info['name'] ?? 'the document'} as a PDF',
          style: text.titleMedium,
        ),
        const SizedBox(height: 4),
        if (recipients.isNotEmpty)
          Text('To $recipients', style: text.bodyMedium),
        if (info['subject'] is String)
          Text('Subject: ${info['subject']}', style: text.bodySmall),
      ],
    );
  }
}

class _OpenDone extends StatelessWidget {
  const _OpenDone({required this.result, required this.onOpen});

  final Map<String, dynamic>? result;
  final ValueChanged<DocSummary> onOpen;

  @override
  Widget build(BuildContext context) {
    final doc = _summary(result);
    if (doc == null || doc.name == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${doc.name} · ${formatMoney(doc.total, doc.currency)}',
              key: const Key('action-done'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton(
            key: const Key('action-open'),
            onPressed: () => onOpen(doc),
            child: const Text('Open to send'),
          ),
        ],
      ),
    );
  }
}

/// A `documents.preview` / `submit` payload, or null if it isn't one.
DocSummary? _summary(Map<String, dynamic>? json) {
  if (json == null ||
      json['doctype'] is! String ||
      json['customer'] is! String) {
    return null;
  }
  try {
    return DocSummary.fromJson(json);
  } catch (_) {
    return null;
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.busy,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final canSend = !busy && controller.text.trim().isNotEmpty;
    return Container(
      decoration: const BoxDecoration(
        color: DaystarColors.surface,
        border: Border(top: BorderSide(color: DaystarColors.ink)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const Key('assistant-input'),
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(
                hintText: 'Ask about sales, customers, quotes…',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(
            key: const Key('assistant-send'),
            tooltip: 'Send',
            onPressed: canSend ? onSend : null,
            icon: const Icon(Icons.arrow_upward),
            style: IconButton.styleFrom(
              backgroundColor: canSend
                  ? DaystarColors.accent
                  : DaystarColors.subtle,
              foregroundColor: DaystarColors.ink,
              shape: const RoundedRectangleBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
