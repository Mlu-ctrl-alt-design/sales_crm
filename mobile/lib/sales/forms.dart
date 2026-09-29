import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../quick_send/models.dart';
import '../theme/daystar_theme.dart';
import 'models.dart';
import 'sales_api.dart';

/// Capture a lead on one screen: who, their company, a note.
///
/// Pops with the saved [LeadDetail].
class NewLeadScreen extends StatefulWidget {
  const NewLeadScreen({super.key, required this.api});

  final SalesApi api;

  @override
  State<NewLeadScreen> createState() => _NewLeadScreenState();
}

class _NewLeadScreenState extends State<NewLeadScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _company = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_first, _last, _mobile, _email, _company, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _value(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final lead = await widget.api.createLead(
        NewLead(
          firstName: _first.text.trim(),
          lastName: _value(_last),
          mobile: _value(_mobile),
          email: _value(_email),
          companyName: _value(_company),
          notes: _value(_notes),
        ),
      );
      if (mounted) Navigator.of(context).pop(lead);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormPage(
      title: 'New lead',
      formKey: _form,
      saving: _saving,
      error: _error,
      saveLabel: 'Save lead',
      onSave: _save,
      children: [
        const _Section('Lead details', 'Who you spoke to.'),
        _Field(
          key: const Key('lead-first-name'),
          controller: _first,
          label: 'First name *',
          capitalization: TextCapitalization.words,
          validator: (v) =>
              (v ?? '').trim().isEmpty ? 'Add their first name.' : null,
        ),
        _Field(
          key: const Key('lead-last-name'),
          controller: _last,
          label: 'Last name',
          capitalization: TextCapitalization.words,
        ),
        _Field(
          key: const Key('lead-mobile'),
          controller: _mobile,
          label: 'Mobile',
          keyboard: TextInputType.phone,
          validator: (_) => _value(_mobile) == null && _value(_email) == null
              ? 'Add a mobile number or an email.'
              : null,
        ),
        _Field(
          key: const Key('lead-email'),
          controller: _email,
          label: 'Email',
          keyboard: TextInputType.emailAddress,
          validator: _emailValidator,
        ),
        const _Section('Company', 'Leave empty for a private buyer.'),
        _Field(
          key: const Key('lead-company'),
          controller: _company,
          label: 'Organisation',
          capitalization: TextCapitalization.words,
        ),
        const _Section('Contact note', 'What they asked for.'),
        _Field(
          key: const Key('lead-notes'),
          controller: _notes,
          label: 'e.g. Wants a quote for 20 panels',
          lines: 3,
        ),
      ],
    );
  }
}

/// Add a customer to quote. Pops with the new [CustomerOption].
class NewCustomerScreen extends StatefulWidget {
  const NewCustomerScreen({super.key, required this.api});

  final SalesApi api;

  @override
  State<NewCustomerScreen> createState() => _NewCustomerScreenState();
}

class _NewCustomerScreenState extends State<NewCustomerScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  bool _company = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final customer = await widget.api.createCustomer(
        name: _name.text.trim(),
        isCompany: _company,
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        mobile: _mobile.text.trim().isEmpty ? null : _mobile.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(customer);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormPage(
      title: 'New customer',
      formKey: _form,
      saving: _saving,
      error: _error,
      saveLabel: 'Save customer',
      onSave: _save,
      children: [
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          key: const Key('customer-type'),
          segments: const [
            ButtonSegment(value: true, label: Text('Company')),
            ButtonSegment(value: false, label: Text('Individual')),
          ],
          selected: {_company},
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            shape: const RoundedRectangleBorder(),
            side: const BorderSide(color: DaystarColors.ink),
            selectedBackgroundColor: DaystarColors.ink,
            selectedForegroundColor: DaystarColors.surface,
          ),
          onSelectionChanged: (s) => setState(() => _company = s.first),
        ),
        _Field(
          key: const Key('customer-name'),
          controller: _name,
          label: _company ? 'Company name *' : 'Full name *',
          capitalization: TextCapitalization.words,
          validator: (v) =>
              (v ?? '').trim().isEmpty ? 'Add the customer\'s name.' : null,
        ),
        _Field(
          key: const Key('customer-email'),
          controller: _email,
          label: 'Email (quotes and invoices go here)',
          keyboard: TextInputType.emailAddress,
          validator: _emailValidator,
        ),
        _Field(
          key: const Key('customer-mobile'),
          controller: _mobile,
          label: 'Mobile',
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        Text(
          'Their price list, tax and address come from the defaults; change '
          'them in Desk if this customer is different.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

String? _emailValidator(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)
      ? null
      : "That email doesn't look right.";
}

class _FormPage extends StatelessWidget {
  const _FormPage({
    required this.title,
    required this.formKey,
    required this.saving,
    required this.error,
    required this.saveLabel,
    required this.onSave,
    required this.children,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final bool saving;
  final String? error;
  final String saveLabel;
  final VoidCallback onSave;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            ...children,
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(
                error!,
                key: const Key('form-error'),
                style: text.bodyMedium?.copyWith(color: DaystarColors.moneyOut),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: DaystarColors.ink)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: FilledButton(
            key: const Key('form-save'),
            onPressed: saving ? null : onSave,
            child: Text(saving ? 'Saving…' : saveLabel),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.hint);

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleLarge?.copyWith(fontSize: 19)),
          const SizedBox(height: 2),
          Text(hint, style: text.bodySmall),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    super.key,
    required this.controller,
    required this.label,
    this.keyboard,
    this.capitalization = TextCapitalization.none,
    this.validator,
    this.lines = 1,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboard;
  final TextCapitalization capitalization;
  final String? Function(String?)? validator;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: lines > 1 ? TextInputType.multiline : keyboard,
        textCapitalization: capitalization,
        autocorrect: keyboard == null,
        minLines: lines,
        maxLines: lines,
        validator: validator,
      ),
    );
  }
}
