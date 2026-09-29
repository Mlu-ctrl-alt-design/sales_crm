/// Typed view of the response from `daystar_mobile.api.mobile_layout.get`.
///
/// The server decides which fields the phone shows for a given DocType and
/// mode. This model is just the shape the form renderer walks — nothing
/// about *how* to render, only *what* is there.
library;

class MobileLayout {
  const MobileLayout({
    required this.doctype,
    required this.mode,
    required this.source,
    required this.tabs,
  });

  final String doctype;
  final String mode;
  final String source;
  final List<LayoutTab> tabs;

  factory MobileLayout.fromJson(Map<String, Object?> json) {
    return MobileLayout(
      doctype: json['doctype'] as String,
      mode: json['mode'] as String,
      source: json['source'] as String,
      tabs: [
        for (final tab in (json['tabs'] as List? ?? const []))
          LayoutTab.fromJson(tab as Map<String, Object?>),
      ],
    );
  }

  /// The fields in reading order — the form renderer's default sequence.
  List<String> get fieldNames => [
    for (final tab in tabs)
      for (final section in tab.sections)
        for (final column in section.columns)
          for (final field in column.fields) field.fieldname,
  ];

  LayoutField? fieldByName(String fieldname) {
    for (final tab in tabs) {
      for (final section in tab.sections) {
        for (final column in section.columns) {
          for (final field in column.fields) {
            if (field.fieldname == fieldname) return field;
          }
        }
      }
    }
    return null;
  }
}

class LayoutTab {
  const LayoutTab({required this.sections});
  final List<LayoutSection> sections;

  factory LayoutTab.fromJson(Map<String, Object?> json) {
    return LayoutTab(
      sections: [
        for (final section in (json['sections'] as List? ?? const []))
          LayoutSection.fromJson(section as Map<String, Object?>),
      ],
    );
  }
}

class LayoutSection {
  const LayoutSection({required this.label, required this.columns});
  final String? label;
  final List<LayoutColumn> columns;

  factory LayoutSection.fromJson(Map<String, Object?> json) {
    return LayoutSection(
      label: json['label'] as String?,
      columns: [
        for (final column in (json['columns'] as List? ?? const []))
          LayoutColumn.fromJson(column as Map<String, Object?>),
      ],
    );
  }
}

class LayoutColumn {
  const LayoutColumn({required this.fields});
  final List<LayoutField> fields;

  factory LayoutColumn.fromJson(Map<String, Object?> json) {
    return LayoutColumn(
      fields: [
        for (final field in (json['fields'] as List? ?? const []))
          LayoutField.fromJson(field as Map<String, Object?>),
      ],
    );
  }
}

/// A single DocField as returned by the server. Only the properties the
/// renderer needs are typed; the rest stay in [extras] for widgets that
/// care about specific flags (e.g. `precision` on Currency).
class LayoutField {
  const LayoutField({
    required this.fieldname,
    required this.fieldtype,
    required this.label,
    required this.reqd,
    required this.hidden,
    required this.options,
    required this.extras,
  });

  final String fieldname;
  final String fieldtype;
  final String? label;
  final bool reqd;
  final bool hidden;
  final String? options;
  final Map<String, Object?> extras;

  factory LayoutField.fromJson(Map<String, Object?> json) {
    return LayoutField(
      fieldname: json['fieldname'] as String,
      fieldtype: json['fieldtype'] as String,
      label: json['label'] as String?,
      reqd: _flag(json['reqd']),
      hidden: _flag(json['hidden']),
      options: json['options'] as String?,
      extras: {...json},
    );
  }

  static bool _flag(Object? value) => value == 1 || value == true;
}
