import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/daystar_theme.dart';
import 'mobile_layout.dart';

/// Builds a form widget for a single [LayoutField]. Central registry so
/// that "add a new fieldtype" is one entry, not scattered across the form.
///
/// The widget is uncontrolled from the outside: it reads from and writes
/// to [values] under the field's [fieldname]. That keeps the form's state
/// a flat `Map<String, Object?>` the submit path can send as JSON.
class FieldWidgetFactory {
  const FieldWidgetFactory();

  Widget build({
    required LayoutField field,
    required Map<String, Object?> values,
    required VoidCallback onChanged,
  }) {
    if (field.hidden) return const SizedBox.shrink();
    final builder =
        _builders[field.fieldtype] ?? _builders['Data']!; // safe default
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: builder(field, values, onChanged),
    );
  }

  static final Map<String, _Builder> _builders = {
    'Data': _dataField,
    'Small Text': _multilineField,
    'Long Text': _multilineField,
    'Text': _multilineField,
    'Text Editor': _multilineField,
    'Int': _numberField,
    'Float': _numberField,
    'Currency': _numberField,
    'Percent': _numberField,
    'Date': _dateField,
    'Datetime': _dateField,
    'Check': _checkField,
    'Select': _selectField,
    'Link': _linkField,
  };
}

typedef _Builder =
    Widget Function(
      LayoutField field,
      Map<String, Object?> values,
      VoidCallback onChanged,
    );

// ---------------- Data ----------------

Widget _dataField(
  LayoutField field,
  Map<String, Object?> values,
  VoidCallback onChanged,
) {
  final keyboard = switch (field.options) {
    'Email' => TextInputType.emailAddress,
    'Phone' => TextInputType.phone,
    'URL' => TextInputType.url,
    _ => TextInputType.text,
  };
  return TextFormField(
    initialValue: values[field.fieldname] as String?,
    decoration: _decoration(field),
    keyboardType: keyboard,
    autocorrect: field.options != 'Email' && field.options != 'URL',
    validator: (v) =>
        (field.reqd && (v == null || v.isEmpty)) ? 'Required' : null,
    onChanged: (v) {
      values[field.fieldname] = v.isEmpty ? null : v;
      onChanged();
    },
  );
}

// ---------------- Multiline ----------------

Widget _multilineField(
  LayoutField field,
  Map<String, Object?> values,
  VoidCallback onChanged,
) {
  return TextFormField(
    initialValue: values[field.fieldname] as String?,
    decoration: _decoration(field),
    keyboardType: TextInputType.multiline,
    minLines: 2,
    maxLines: 5,
    validator: (v) =>
        (field.reqd && (v == null || v.isEmpty)) ? 'Required' : null,
    onChanged: (v) {
      values[field.fieldname] = v.isEmpty ? null : v;
      onChanged();
    },
  );
}

// ---------------- Numeric ----------------

Widget _numberField(
  LayoutField field,
  Map<String, Object?> values,
  VoidCallback onChanged,
) {
  final isInt = field.fieldtype == 'Int';
  return TextFormField(
    initialValue: values[field.fieldname]?.toString(),
    decoration: _decoration(field),
    keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(isInt ? r'[0-9]' : r'[0-9.]')),
    ],
    validator: (v) {
      if (field.reqd && (v == null || v.isEmpty)) return 'Required';
      if (v == null || v.isEmpty) return null;
      if (isInt) {
        if (int.tryParse(v) == null) return 'Whole number';
      } else {
        if (double.tryParse(v) == null) return 'Number';
      }
      return null;
    },
    onChanged: (v) {
      if (v.isEmpty) {
        values[field.fieldname] = null;
      } else {
        values[field.fieldname] = isInt ? int.tryParse(v) : double.tryParse(v);
      }
      onChanged();
    },
  );
}

// ---------------- Date ----------------

Widget _dateField(
  LayoutField field,
  Map<String, Object?> values,
  VoidCallback onChanged,
) {
  return _DateFieldWidget(
    field: field,
    values: values,
    onChanged: onChanged,
  );
}

class _DateFieldWidget extends StatefulWidget {
  const _DateFieldWidget({
    required this.field,
    required this.values,
    required this.onChanged,
  });

  final LayoutField field;
  final Map<String, Object?> values;
  final VoidCallback onChanged;

  @override
  State<_DateFieldWidget> createState() => _DateFieldWidgetState();
}

class _DateFieldWidgetState extends State<_DateFieldWidget> {
  late final _controller = TextEditingController(
    text: widget.values[widget.field.fieldname] as String?,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_controller.text) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    final text = _isoDate(picked);
    setState(() => _controller.text = text);
    widget.values[widget.field.fieldname] = text;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      onTap: _open,
      decoration: _decoration(widget.field).copyWith(
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
      ),
      validator: (v) =>
          (widget.field.reqd && (v == null || v.isEmpty)) ? 'Required' : null,
    );
  }
}

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, "0")}-'
    '${d.month.toString().padLeft(2, "0")}-'
    '${d.day.toString().padLeft(2, "0")}';

// ---------------- Check ----------------

Widget _checkField(
  LayoutField field,
  Map<String, Object?> values,
  VoidCallback onChanged,
) {
  final current = values[field.fieldname];
  final on = current == true || current == 1;
  return _CheckFieldWidget(
    field: field,
    initialValue: on,
    onChanged: (v) {
      values[field.fieldname] = v ? 1 : 0;
      onChanged();
    },
  );
}

class _CheckFieldWidget extends StatefulWidget {
  const _CheckFieldWidget({
    required this.field,
    required this.initialValue,
    required this.onChanged,
  });

  final LayoutField field;
  final bool initialValue;
  final ValueChanged<bool> onChanged;

  @override
  State<_CheckFieldWidget> createState() => _CheckFieldWidgetState();
}

class _CheckFieldWidgetState extends State<_CheckFieldWidget> {
  late bool _value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(widget.field.label ?? widget.field.fieldname),
      value: _value,
      onChanged: (v) {
        setState(() => _value = v);
        widget.onChanged(v);
      },
    );
  }
}

// ---------------- Select ----------------

Widget _selectField(
  LayoutField field,
  Map<String, Object?> values,
  VoidCallback onChanged,
) {
  final options = (field.options ?? '')
      .split('\n')
      .where((s) => s.isNotEmpty)
      .toList();
  return DropdownButtonFormField<String>(
    initialValue: values[field.fieldname] as String?,
    decoration: _decoration(field),
    items: [
      for (final option in options)
        DropdownMenuItem(value: option, child: Text(option)),
    ],
    validator: (v) =>
        (field.reqd && (v == null || v.isEmpty)) ? 'Required' : null,
    onChanged: (v) {
      values[field.fieldname] = v;
      onChanged();
    },
  );
}

// ---------------- Link ----------------

/// v1: a plain text field the rep types into. Rendering a proper Link
/// picker (search against `frappe.client.get_list` with the target
/// doctype from [LayoutField.options]) is the next iteration — see
/// `MinimalFormScreen` docstring.
Widget _linkField(
  LayoutField field,
  Map<String, Object?> values,
  VoidCallback onChanged,
) {
  return TextFormField(
    initialValue: values[field.fieldname] as String?,
    decoration: _decoration(field).copyWith(
      hintText: field.options != null ? 'Pick a ${field.options}' : null,
    ),
    validator: (v) =>
        (field.reqd && (v == null || v.isEmpty)) ? 'Required' : null,
    onChanged: (v) {
      values[field.fieldname] = v.isEmpty ? null : v;
      onChanged();
    },
  );
}

// ---------------- Decoration ----------------

InputDecoration _decoration(LayoutField field) => InputDecoration(
  labelText: field.label ?? field.fieldname,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(DaystarRadius.field),
  ),
);
