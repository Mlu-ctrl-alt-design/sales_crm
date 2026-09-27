import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme/daystar_theme.dart';
import '../theme/money.dart';
import 'models.dart';
import 'pdf_share.dart';
import 'quick_send_api.dart';

/// The submitted document's number, then email it or share the PDF.
class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({
    super.key,
    required this.api,
    required this.doc,
    required this.sharePdf,
  });

  final QuickSendApi api;
  final DocSummary doc;
  final PdfSharer sharePdf;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

enum _Status { idle, busy, done, failed }

class _ReceiptScreenState extends State<ReceiptScreen> {
  late final _to = TextEditingController(text: widget.doc.send?.to ?? '');
  final _shareButton = GlobalKey();

  _Status _email = _Status.idle;
  String? _emailError;
  String? _sentTo;

  _Status _share = _Status.idle;
  String? _shareError;

  DocSummary get _doc => widget.doc;

  @override
  void dispose() {
    _to.dispose();
    super.dispose();
  }

  List<String> get _recipients => _to.text
      .split(RegExp(r'[,;\s]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _sendEmail() async {
    final to = _recipients;
    if (to.isEmpty) {
      setState(() {
        _email = _Status.failed;
        _emailError = 'Add an email address to send to.';
      });
      return;
    }
    setState(() {
      _email = _Status.busy;
      _emailError = null;
    });
    try {
      await widget.api.sendEmail(
        _doc.kind,
        _doc.name!,
        to,
        subject: _doc.send?.subject,
        message: _doc.send?.message,
      );
      if (!mounted) return;
      setState(() {
        _email = _Status.done;
        _sentTo = to.join(', ');
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _email = _Status.failed;
        _emailError = e.message;
      });
    }
  }

  Future<void> _sharePdf() async {
    setState(() {
      _share = _Status.busy;
      _shareError = null;
    });
    try {
      final pdf = await widget.api.downloadPdf(_doc.kind, _doc.name!);
      final box = _shareButton.currentContext?.findRenderObject() as RenderBox?;
      await widget.sharePdf(
        pdf,
        pdfFileName(_doc.name!),
        origin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
      if (mounted) setState(() => _share = _Status.idle);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _share = _Status.failed;
        _shareError = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final from = _doc.send?.from;
    return Scaffold(
      appBar: AppBar(
        title: Text(_doc.kind.label),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            key: const Key('receipt-done'),
            style: TextButton.styleFrom(foregroundColor: DaystarColors.surface),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                color: DaystarColors.moneyIn,
                child: const Icon(Icons.check, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Eyebrow('${_doc.kind.label} submitted'),
            ],
          ),
          const SizedBox(height: 14),
          SelectableText(
            _doc.name ?? '',
            key: const Key('receipt-name'),
            style: text.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${_doc.customerName} · ${formatMoney(_doc.total, _doc.currency)}',
            style: text.bodyLarge?.copyWith(color: DaystarColors.muted),
          ),
          const SizedBox(height: 36),
          const Eyebrow('Email'),
          const SizedBox(height: 4),
          TextField(
            key: const Key('email-to'),
            controller: _to,
            enabled: _email != _Status.busy,
            decoration: const InputDecoration(labelText: 'To'),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
          ),
          const SizedBox(height: 8),
          Text(
            from == null
                ? "Daystar has no email account to send from yet. Ask Mlu to "
                      'set one up, or share the PDF below.'
                : 'Sent from $from, with the PDF attached. It shows on the '
                      "${_doc.kind.noun}'s timeline in Desk.",
            style: text.bodySmall,
          ),
          const SizedBox(height: 16),
          if (_email == _Status.done)
            Row(
              key: const Key('email-sent'),
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  color: DaystarColors.moneyIn,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Emailed to $_sentTo', style: text.titleMedium),
                ),
              ],
            )
          else
            FilledButton.icon(
              key: const Key('send-email'),
              onPressed: _email == _Status.busy ? null : _sendEmail,
              icon: _email == _Status.busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DaystarColors.muted,
                      ),
                    )
                  : const Icon(Icons.mail_outline),
              label: Text(
                _email == _Status.busy
                    ? 'Sending…'
                    : _email == _Status.failed
                    ? 'Try again'
                    : 'Email PDF',
              ),
            ),
          if (_emailError != null) ...[
            const SizedBox(height: 10),
            Text(
              _emailError!,
              key: const Key('email-error'),
              style: text.bodyMedium?.copyWith(color: DaystarColors.moneyOut),
            ),
          ],
          const SizedBox(height: 36),
          const Eyebrow('WhatsApp and other apps'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: _shareButton,
            onPressed: _share == _Status.busy ? null : _sharePdf,
            icon: _share == _Status.busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
            label: Text(
              _share == _Status.busy ? 'Getting the PDF…' : 'Share PDF',
            ),
          ),
          if (_shareError != null) ...[
            const SizedBox(height: 10),
            Text(
              _shareError!,
              style: text.bodyMedium?.copyWith(color: DaystarColors.moneyOut),
            ),
          ],
        ],
      ),
    );
  }
}
