import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hands a PDF to the phone's share sheet (WhatsApp, Mail, Files...).
///
/// [origin] anchors the sheet on iPad; phones ignore it.
typedef PdfSharer =
    Future<void> Function(Uint8List pdf, String fileName, {Rect? origin});

Future<void> shareViaSheet(
  Uint8List pdf,
  String fileName, {
  Rect? origin,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(pdf, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/pdf')],
      sharePositionOrigin: origin,
    ),
  );
}

/// "SAL-QTN-2026-00012.pdf": safe for any app the file is shared to.
String pdfFileName(String docName) =>
    '${docName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-')}.pdf';
