import 'package:daystar_sales/api/api_client.dart';
import 'package:daystar_sales/dashboard/dashboard_screen.dart';
import 'package:daystar_sales/dashboard/dates.dart';
import 'package:daystar_sales/dashboard/models.dart';
import 'package:daystar_sales/theme/daystar_theme.dart';
import 'package:daystar_sales/theme/money.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

Future<void> pumpDashboard(WidgetTester tester, FakeDashboardApi api) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DaystarTheme.light(),
      home: Scaffold(
        body: DashboardScreen(api: api, now: () => DateTime(2026, 9, 27, 19)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String plain(String s) => s.replaceAll('\u00a0', ' ');

/// Text under [key] containing [text]; every Text renders one RichText.
Finder textIn(String key, String text) => find.descendant(
  of: find.byKey(Key(key)),
  matching: find.byWidgetPredicate(
    (w) => w is RichText && plain(w.text.toPlainText()).contains(text),
  ),
);

void main() {
  group('date labels', () {
    test('whole month, within a month, across months, other years', () {
      expect(
        rangeLabel(DateTime(2026, 8, 1), DateTime(2026, 8, 31)),
        'Aug 2026',
      );
      expect(
        rangeLabel(DateTime(2026, 9, 1), DateTime(2026, 9, 27), thisYear: 2026),
        '1–27 Sep',
      );
      expect(
        rangeLabel(DateTime(2026, 3, 1), DateTime(2026, 9, 27), thisYear: 2026),
        '1 Mar – 27 Sep',
      );
      expect(
        rangeLabel(DateTime(2025, 3, 1), DateTime(2025, 9, 27), thisYear: 2026),
        '1 Mar – 27 Sep 2025',
      );
      expect(
        rangeLabel(
          DateTime(2025, 12, 1),
          DateTime(2026, 1, 15),
          thisYear: 2026,
        ),
        '1 Dec 2025 – 15 Jan',
      );
    });

    test('updated time', () {
      final now = DateTime(2026, 9, 27, 19);
      expect(updatedLabel(DateTime(2026, 9, 27, 18, 52), now), '18:52');
      expect(updatedLabel(DateTime(2026, 9, 26, 8, 5), now), '26 Sep, 08:05');
    });
  });

  test('change ratio is null with nothing to compare', () {
    expect(const Figure(10, 0).changeRatio, isNull);
    expect(const Figure(110, 100).changeRatio, closeTo(0.1, 1e-9));
  });

  testWidgets('owner: profit up front, each figure with its change', (
    tester,
  ) async {
    await pumpDashboard(tester, FakeDashboardApi());

    expect(textIn('kpi-profit', plain(formatZar(48250))), findsOneWidget);
    expect(textIn('kpi-profit', '▲ R 5 250,00 (12%)'), findsOneWidget);
    expect(textIn('kpi-profit', 'vs 1–27 Aug'), findsOneWidget);

    expect(textIn('kpi-sales', '▼ R 14 600,00 (7%)'), findsOneWidget);
    expect(textIn('kpi-sales', '14 invoices, excl. VAT'), findsOneWidget);
    expect(textIn('kpi-receivables', 'R 24 600,00 overdue'), findsOneWidget);
    expect(textIn('kpi-receivables', 'vs 27 Aug'), findsOneWidget);
    expect(find.byKey(const Key('kpi-paid-out')), findsOneWidget);

    expect(textIn('pipeline-quotes', 'R 126 500,00'), findsOneWidget);
    expect(
      textIn(
        'pipeline-new-leads',
        '6 new leads this period, 2 more than in 1–27 Aug',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('1–27 SEP · UPDATED 18:52'), findsOneWidget);
  });

  testWidgets('rep: own sales and what they are owed, never company money', (
    tester,
  ) async {
    await pumpDashboard(tester, FakeDashboardApi(json: repJson()));

    expect(textIn('kpi-my-sales', plain(formatZar(32000))), findsOneWidget);
    expect(
      textIn('kpi-my-outstanding', '2 invoices, nothing overdue'),
      findsOneWidget,
    );
    expect(find.text('MY PIPELINE · OPEN NOW'), findsOneWidget);
    expect(find.byKey(const Key('kpi-profit')), findsNothing);
    expect(find.byKey(const Key('kpi-paid-out')), findsNothing);
    expect(find.byKey(const Key('rep-unlinked')), findsNothing);
  });

  testWidgets('a rep with no sales person link is told why it is empty', (
    tester,
  ) async {
    await pumpDashboard(tester, FakeDashboardApi(json: repJson(linked: false)));
    expect(find.byKey(const Key('rep-unlinked')), findsOneWidget);
  });

  testWidgets('switching period loads it once; switching back is instant', (
    tester,
  ) async {
    final api = FakeDashboardApi();
    await pumpDashboard(tester, api);

    await tester.tap(find.byKey(const Key('period-last_month')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('period-this_month')));
    await tester.pumpAndSettle();

    expect(api.calls, [
      (DashboardPeriod.thisMonth, false),
      (DashboardPeriod.lastMonth, false),
    ]);
  });

  testWidgets('pull to refresh asks the server to skip its cache', (
    tester,
  ) async {
    final api = FakeDashboardApi();
    await pumpDashboard(tester, api);

    await tester.fling(
      find.byKey(const Key('kpi-profit')),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(api.calls.last, (DashboardPeriod.thisMonth, true));
  });

  testWidgets('a failed load explains and retries', (tester) async {
    final api = FakeDashboardApi(
      error: ApiException("Couldn't reach Daystar.", ApiErrorKind.offline),
    );
    await pumpDashboard(tester, api);
    expect(find.byKey(const Key('dashboard-error')), findsOneWidget);

    api.error = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('kpi-profit')), findsOneWidget);
  });
}
