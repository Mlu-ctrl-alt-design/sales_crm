import 'dart:convert';
import 'dart:typed_data';

import 'package:daystar_sales/api/api_client.dart';
import 'package:daystar_sales/auth/auth_repository.dart';
import 'package:daystar_sales/auth/biometric_lock.dart';
import 'package:daystar_sales/auth/device_prefs.dart';
import 'package:daystar_sales/auth/key_value_store.dart';
import 'package:daystar_sales/quick_send/draft.dart';
import 'package:daystar_sales/quick_send/models.dart';
import 'package:daystar_sales/quick_send/quick_send_api.dart';
import 'package:daystar_sales/shell/home_shell.dart';
import 'package:daystar_sales/startup/app_status.dart';
import 'package:daystar_sales/startup/app_status_service.dart';

class FakeStatusService implements AppStatusService {
  FakeStatusService(this.result);
  final Future<AppStatus> Function() result;

  @override
  Future<AppStatus> fetch() => result();
}

class FakeAuth implements AuthRepository {
  FakeAuth({this.stored});

  Session? stored;
  int logins = 0;

  @override
  Future<Session?> restore() async => stored;

  @override
  Future<Session> login({
    required String username,
    required String password,
  }) async {
    logins++;
    return stored = Session(user: username);
  }

  @override
  Future<void> logout() async => stored = null;
}

class MemoryPrefs implements DevicePrefs {
  String? email;
  bool unlock = false;
  bool offered = false;

  @override
  Future<String?> lastEmail() async => email;
  @override
  Future<void> setLastEmail(String value) async => email = value;
  @override
  Future<bool> biometricUnlock() async => unlock;
  @override
  Future<void> setBiometricUnlock(bool enabled) async => unlock = enabled;
  @override
  Future<bool> biometricOffered() async => offered;
  @override
  Future<void> setBiometricOffered() async => offered = true;
}

class FakeBiometrics implements BiometricLock {
  FakeBiometrics({this.kind = BiometricKind.face, this.succeeds = true});

  BiometricKind? kind;
  bool succeeds;
  int prompts = 0;

  @override
  Future<BiometricKind?> available() async => kind;

  @override
  Future<bool> unlock(String reason) async {
    prompts++;
    return succeeds;
  }
}

const openStatus = AppStatus(enabled: true, maintenanceMode: false);

class MemoryStore implements KeyValueStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

const acme = CustomerOption(
  name: 'CUST-0001',
  customerName: 'Acme Farms',
  email: 'buyer@acme.co.za',
);
const panel = ItemOption(
  itemCode: 'PANEL-450',
  itemName: 'Solar panel 450W',
  uom: 'Nos',
  rate: 2400,
);
const bracket = ItemOption(
  itemCode: 'BRACKET',
  itemName: 'Roof bracket',
  uom: 'Nos',
  rate: 150,
);

/// Behaves like `daystar_mobile.api.documents` with 15% VAT.
class FakeQuickSendApi implements QuickSendApi {
  List<CustomerOption> customers = [acme];
  List<ItemOption> items = [panel, bracket];
  bool canEditPrices = true;
  ApiException? previewError;

  /// Next submit creates the document but the answer never arrives.
  bool loseNextAnswer = false;

  /// Next submit is refused outright.
  ApiException? submitError;
  ApiException? emailError;

  final submitKeys = <String>[];
  final created = <String, DocSummary>{};
  final emails = <({String name, List<String> to})>[];
  final pdfDownloads = <String>[];
  int previews = 0;

  @override
  Future<List<CustomerOption>> searchCustomers(String text) async => [
    for (final c in customers)
      if (c.customerName.toLowerCase().contains(text.toLowerCase())) c,
  ];

  @override
  Future<ItemSearch> searchItems(String customer, String text) async =>
      ItemSearch(
        currency: 'ZAR',
        priceList: 'Standard Selling',
        items: [
          for (final i in items)
            if (i.itemName.toLowerCase().contains(text.toLowerCase())) i,
        ],
      );

  @override
  Future<DocSummary> preview(
    DocKind kind,
    String customer,
    List<DraftLine> lines,
  ) async {
    previews++;
    if (previewError != null) throw previewError!;
    return _build(kind, customer, lines);
  }

  @override
  Future<DocSummary> submit(
    DocKind kind,
    String customer,
    List<DraftLine> lines,
    String key,
  ) async {
    submitKeys.add(key);
    if (submitError != null) {
      final error = submitError!;
      submitError = null;
      throw error;
    }
    final doc = created[key] ??= _build(
      kind,
      customer,
      lines,
      name:
          '${kind == DocKind.quote ? 'SAL-QTN' : 'ACC-SINV'}-2026-'
          '${(created.length + 1).toString().padLeft(5, '0')}',
    );
    if (loseNextAnswer) {
      loseNextAnswer = false;
      throw ApiException('No answer', ApiErrorKind.offline);
    }
    return doc;
  }

  @override
  Future<String> sendEmail(
    DocKind kind,
    String name,
    List<String> to, {
    String? subject,
    String? message,
  }) async {
    if (emailError != null) throw emailError!;
    emails.add((name: name, to: to));
    return 'mlu@thedaystar.co.za';
  }

  @override
  Future<Uint8List> downloadPdf(DocKind kind, String name) async {
    pdfDownloads.add(name);
    return Uint8List.fromList(utf8.encode('%PDF-1.4'));
  }

  DocSummary _build(
    DocKind kind,
    String customer,
    List<DraftLine> lines, {
    String? name,
  }) {
    final summaryLines = [
      for (final line in lines)
        () {
          final rate =
              line.rate ??
              items.firstWhere((i) => i.itemCode == line.itemCode).rate ??
              0;
          return SummaryLine(
            itemCode: line.itemCode,
            itemName: line.itemName,
            qty: line.qty,
            uom: line.uom,
            rate: rate,
            priceListRate: items
                .firstWhere((i) => i.itemCode == line.itemCode)
                .rate,
            amount: rate * line.qty,
          );
        }(),
    ];
    final net = summaryLines.fold<double>(0, (sum, l) => sum + l.amount);
    final vat = net * 0.15;
    return DocSummary(
      kind: kind,
      name: name,
      customer: customer,
      customerName: customers
          .firstWhere((c) => c.name == customer)
          .customerName,
      currency: 'ZAR',
      canEditPrices: canEditPrices,
      lines: summaryLines,
      taxes: [TaxLine(description: 'VAT 15%', rate: 15, amount: vat)],
      netTotal: net,
      totalTaxes: vat,
      total: net + vat,
      send: name == null
          ? null
          : const SendDefaults(
              to: 'buyer@acme.co.za',
              from: 'mlu@thedaystar.co.za',
            ),
    );
  }
}

/// The signed-in app with quick-send fakes.
HomeShell testHome({
  FakeQuickSendApi? api,
  MemoryStore? drafts,
  List<String>? shared,
}) => HomeShell(
  quickSend: api ?? FakeQuickSendApi(),
  drafts: drafts ?? MemoryStore(),
  sharePdf: (pdf, fileName, {origin}) async => shared?.add(fileName),
);
