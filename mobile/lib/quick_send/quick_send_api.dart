import 'dart:typed_data';

import '../api/api_client.dart';
import 'draft.dart';
import 'models.dart';

/// `daystar_mobile.api.documents`, plus Frappe's PDF download.
abstract class QuickSendApi {
  Future<List<CustomerOption>> searchCustomers(String text);

  Future<ItemSearch> searchItems(String customer, String text);

  /// Submitted documents of [kind], newest first, matching [text].
  Future<List<DocListing>> searchDocuments(DocKind kind, String text);

  /// A submitted document with its send defaults.
  Future<DocSummary> getDocument(DocKind kind, String name);

  /// The document as it would be submitted; nothing is saved.
  Future<DocSummary> preview(
    DocKind kind,
    String customer,
    List<DraftLine> lines,
  );

  /// Creates and submits once per [key]; a retry returns the same document.
  Future<DocSummary> submit(
    DocKind kind,
    String customer,
    List<DraftLine> lines,
    String key,
  );

  /// Emails the PDF; returns the address it was sent from.
  Future<String> sendEmail(
    DocKind kind,
    String name,
    List<String> to, {
    String? subject,
    String? message,
  });

  Future<Uint8List> downloadPdf(DocKind kind, String name);
}

class HttpQuickSendApi implements QuickSendApi {
  HttpQuickSendApi(this._client);

  final ApiClient _client;
  static const _base = 'daystar_mobile.api.documents';

  @override
  Future<List<CustomerOption>> searchCustomers(String text) async {
    final result = await _client.get('$_base.search_customers', {'txt': text});
    return [
      for (final row in (result as List? ?? const []))
        CustomerOption.fromJson(row as Map<String, dynamic>),
    ];
  }

  @override
  Future<ItemSearch> searchItems(String customer, String text) async {
    final result = await _client.get('$_base.search_items', {
      'customer': customer,
      'txt': text,
    });
    return ItemSearch.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<List<DocListing>> searchDocuments(DocKind kind, String text) async {
    final result = await _client.get('$_base.search_documents', {
      'doctype': kind.doctype,
      'txt': text,
    });
    return [
      for (final row in (result as List? ?? const []))
        DocListing.fromJson(row as Map<String, dynamic>),
    ];
  }

  @override
  Future<DocSummary> getDocument(DocKind kind, String name) async {
    final result = await _client.get('$_base.get_document', {
      'doctype': kind.doctype,
      'name': name,
    });
    return DocSummary.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<DocSummary> preview(
    DocKind kind,
    String customer,
    List<DraftLine> lines,
  ) async {
    final result = await _client.post('$_base.preview', {
      'doctype': kind.doctype,
      'customer': customer,
      'items': [for (final line in lines) line.toRequest()],
    });
    return DocSummary.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<DocSummary> submit(
    DocKind kind,
    String customer,
    List<DraftLine> lines,
    String key,
  ) async {
    final result = await _client.post('$_base.submit', {
      'doctype': kind.doctype,
      'customer': customer,
      'items': [for (final line in lines) line.toRequest()],
      'key': key,
    });
    return DocSummary.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<String> sendEmail(
    DocKind kind,
    String name,
    List<String> to, {
    String? subject,
    String? message,
  }) async {
    final result = await _client.post('$_base.send_email', {
      'doctype': kind.doctype,
      'name': name,
      'recipients': to,
      'subject': ?subject,
      'message': ?message,
    });
    return (result as Map<String, dynamic>)['sender'] as String? ?? '';
  }

  @override
  Future<Uint8List> downloadPdf(DocKind kind, String name) {
    return _client.download('frappe.utils.print_format.download_pdf', {
      'doctype': kind.doctype,
      'name': name,
    });
  }
}
