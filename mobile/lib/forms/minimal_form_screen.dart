import 'package:flutter/material.dart';

import '../theme/daystar_theme.dart';
import 'field_widgets.dart';
import 'form_submit_service.dart';
import 'mobile_layout.dart';
import 'mobile_layout_service.dart';

/// A form whose *fields* come from the server — the phone renders whatever
/// `daystar_mobile.api.mobile_layout.get(doctype, mode)` returns. Change a
/// Mobile Field Layout on the Desk, next open of this screen shows the new
/// shape. No app rebuild.
///
/// v1 fields: Data, Small Text / Long Text, Int / Float / Currency, Date,
/// Datetime, Check, Select, Link (typed by name).
///
/// Future: replace the Link widget with a proper picker against
/// `frappe.client.get_list` on the field's `options` doctype; add tab
/// support once we have a Detail-mode layout that uses more than one tab.
class MinimalFormScreen extends StatefulWidget {
  const MinimalFormScreen({
    super.key,
    required this.doctype,
    required this.mode,
    required this.title,
    required this.layoutService,
    required this.submitService,
  });

  final String doctype;
  final String mode;
  final String title;
  final MobileLayoutService layoutService;
  final FormSubmitService submitService;

  @override
  State<MinimalFormScreen> createState() => _MinimalFormScreenState();
}

class _MinimalFormScreenState extends State<MinimalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _values = <String, Object?>{};
  final _factory = const FieldWidgetFactory();

  Future<MobileLayout>? _future;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = widget.layoutService.fetch(
      doctype: widget.doctype,
      mode: widget.mode,
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final name = await widget.submitService.insert(
        doctype: widget.doctype,
        values: _values,
      );
      if (!mounted) return;
      Navigator.of(context).pop(name);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${name.isNotEmpty ? name : widget.doctype}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<MobileLayout>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _LayoutError(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {
                _future = widget.layoutService.fetch(
                  doctype: widget.doctype,
                  mode: widget.mode,
                );
              }),
            );
          }
          final layout = snapshot.data!;
          return _LayoutBody(
            layout: layout,
            formKey: _formKey,
            factory: _factory,
            values: _values,
            submitting: _submitting,
            onSubmit: _submit,
          );
        },
      ),
    );
  }
}

class _LayoutBody extends StatelessWidget {
  const _LayoutBody({
    required this.layout,
    required this.formKey,
    required this.factory,
    required this.values,
    required this.submitting,
    required this.onSubmit,
  });

  final MobileLayout layout;
  final GlobalKey<FormState> formKey;
  final FieldWidgetFactory factory;
  final Map<String, Object?> values;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              for (final tab in layout.tabs)
                for (final section in tab.sections)
                  _Section(
                    label: section.label,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final column in section.columns)
                          ...column.fields.map(
                            (field) => factory.build(
                              field: field,
                              values: values,
                              onChanged: () {},
                            ),
                          ),
                      ],
                    ),
                  ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('minimal-form-submit'),
                onPressed: submitting ? null : onSubmit,
                child: Text(submitting ? 'Saving…' : 'Save'),
              ),
              if (layout.source != 'Mobile Field Layout')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Layout source: ${layout.source}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DaystarColors.muted,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});
  final String? label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null && label!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                label!,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: DaystarColors.muted,
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _LayoutError extends StatelessWidget {
  const _LayoutError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              'Could not load the form',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
