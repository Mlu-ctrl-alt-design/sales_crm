"""Dashboard: period maths, owner figures from ERPNext's reports, rep scoping."""

from datetime import date

import frappe
from frappe.tests import IntegrationTestCase
from frappe.utils import add_months, flt, getdate, nowdate

from daystar_mobile.api import dashboard
from daystar_mobile.tests.test_price_lock import REP, setup_fixtures


class TestPeriods(IntegrationTestCase):
	def span(self, period, today):
		return dashboard.resolve_period(period, getdate(today), "_Test Company")

	def test_this_month_compares_with_the_same_days_last_month(self):
		span = self.span("this_month", "2026-09-27")
		self.assertEqual(
			(span["from"], span["to"], span["prev_from"], span["prev_to"]),
			(date(2026, 9, 1), date(2026, 9, 27), date(2026, 8, 1), date(2026, 8, 27)),
		)

	def test_month_end_clamps_to_the_shorter_month(self):
		span = self.span("this_month", "2026-03-31")
		self.assertEqual((span["prev_from"], span["prev_to"]), (date(2026, 2, 1), date(2026, 2, 28)))

	def test_last_month_compares_whole_months(self):
		span = self.span("last_month", "2026-09-27")
		self.assertEqual(
			(span["from"], span["to"], span["prev_from"], span["prev_to"]),
			(date(2026, 8, 1), date(2026, 8, 31), date(2026, 7, 1), date(2026, 7, 31)),
		)

	def test_quarter_and_year_follow_the_fiscal_year(self):
		from erpnext.accounts.utils import get_fiscal_year

		today = getdate(nowdate())
		fy_start = getdate(get_fiscal_year(today, company="_Test Company")[1])

		year = self.span("this_fy", today)
		self.assertEqual((year["from"], year["to"]), (fy_start, today))
		self.assertLess(year["prev_to"], fy_start)

		quarter = self.span("this_quarter", today)
		self.assertLessEqual(fy_start, quarter["from"])
		self.assertLessEqual(quarter["from"], today)
		self.assertEqual((quarter["from"].month - fy_start.month) % 3, 0)
		self.assertLess(quarter["prev_to"], quarter["from"])

	def test_a_chosen_month_compares_whole_months(self):
		span = self.span("month:2026-03", "2026-09-27")
		self.assertEqual(
			(span["from"], span["to"], span["prev_from"], span["prev_to"]),
			(date(2026, 3, 1), date(2026, 3, 31), date(2026, 2, 1), date(2026, 2, 28)),
		)

	def test_choosing_the_current_month_runs_to_date(self):
		self.assertEqual(self.span("month:2026-09", "2026-09-27"), self.span("this_month", "2026-09-27"))

	def test_a_month_in_the_future_or_malformed_is_refused(self):
		next_month = getdate(add_months(nowdate(), 1))
		for period in (f"month:{next_month:%Y-%m}", "month:2026-13", "month:26-07"):
			with self.assertRaises(frappe.ValidationError):
				dashboard.get(period)

	def test_unknown_period_is_refused(self):
		with self.assertRaises(frappe.ValidationError):
			dashboard.get("yesterday")


class TestOwnerDashboard(IntegrationTestCase):
	@classmethod
	def setUpClass(cls):
		super().setUpClass()
		setup_fixtures()
		frappe.conf.daystar_mobile_company = "_Test Company"

	@classmethod
	def tearDownClass(cls):
		frappe.conf.pop("daystar_mobile_company", None)
		super().tearDownClass()

	def test_an_invoice_moves_sales_profit_and_receivables(self):
		from erpnext.accounts.doctype.sales_invoice.test_sales_invoice import create_sales_invoice

		before = dashboard.get("this_month", refresh=1)
		self.assertEqual(before["view"], "owner")

		invoice = create_sales_invoice(rate=1000, qty=1)
		after = dashboard.get("this_month", refresh=1)

		def delta(key):
			return flt(after["kpis"][key]["value"] - before["kpis"][key]["value"], 2)

		self.assertEqual(delta("sales"), flt(invoice.base_net_total, 2))
		self.assertEqual(after["kpis"]["sales"]["count"], before["kpis"]["sales"]["count"] + 1)
		self.assertEqual(delta("profit"), flt(invoice.base_net_total, 2))
		self.assertEqual(delta("receivables"), flt(invoice.base_grand_total, 2))

	def test_profit_is_the_profit_and_loss_statement(self):
		from erpnext.accounts.report.profit_and_loss_statement.profit_and_loss_statement import execute

		today = nowdate()
		start = str(getdate(today).replace(day=1))
		filters = frappe._dict(
			company="_Test Company",
			filter_based_on="Date Range",
			period_start_date=start,
			period_end_date=today,
			periodicity="Monthly",
			accumulated_values=0,
			include_default_book_entries=1,
		)
		_columns, data, *_ = execute(filters)
		net = next((row for row in data if row.get("warn_if_negative")), {})
		self.assertEqual(flt(dashboard.profit("_Test Company", start, today), 2), flt(net.get("total"), 2))

	def test_owner_figures_are_cached_until_refresh(self):
		first = dashboard.get("last_month", refresh=1)
		frappe.cache.set_value(
			f"daystar_mobile:dashboard:owner:_Test Company:last_month:{first['period']['to']}",
			{**{k: v for k, v in first.items() if k in ("view", "kpis", "pipeline")}, "view": "cached"},
		)
		self.assertEqual(dashboard.get("last_month")["view"], "cached")
		self.assertEqual(dashboard.get("last_month", refresh=1)["view"], "owner")


class TestRepDashboard(IntegrationTestCase):
	@classmethod
	def setUpClass(cls):
		super().setUpClass()
		setup_fixtures()
		frappe.conf.daystar_mobile_company = "_Test Company"

	@classmethod
	def tearDownClass(cls):
		frappe.conf.pop("daystar_mobile_company", None)
		super().tearDownClass()

	def test_a_rep_never_gets_company_money(self):
		with self.set_user(REP):
			result = dashboard.get("this_month")

		self.assertEqual(result["view"], "rep")
		flat = frappe.as_json(result)
		for secret in ("profit", "paid_out", "receivables"):
			self.assertNotIn(f'"{secret}"', flat)

	def test_rep_sales_are_their_share_of_the_sales_team(self):
		from erpnext.accounts.doctype.sales_invoice.test_sales_invoice import create_sales_invoice
		from erpnext.setup.doctype.employee.test_employee import make_employee

		employee = make_employee(REP, company="_Test Company")
		person = frappe.db.get_value("Sales Person", {"employee": employee})
		if not person:
			person = (
				frappe.get_doc(
					{
						"doctype": "Sales Person",
						"sales_person_name": "_Test DM Rep",
						"employee": employee,
						"enabled": 1,
					}
				)
				.insert(ignore_permissions=True)
				.name
			)

		with self.set_user(REP):
			before = dashboard.get("this_month")

		invoice = create_sales_invoice(rate=1000, qty=1, do_not_save=True)
		invoice.append("sales_team", {"sales_person": person, "allocated_percentage": 50})
		invoice.insert()
		invoice.submit()

		with self.set_user(REP):
			after = dashboard.get("this_month")

		self.assertTrue(after["linked"])
		self.assertEqual(
			flt(after["kpis"]["my_sales"]["value"] - before["kpis"]["my_sales"]["value"], 2),
			flt(invoice.base_net_total / 2, 2),
		)
		self.assertEqual(
			after["kpis"]["my_outstanding"]["count"], before["kpis"]["my_outstanding"]["count"] + 1
		)

	def test_a_rep_with_no_sales_person_sees_zeros_not_everyone(self):
		self.assertEqual(dashboard.sales_persons_for("nobody@example.com"), [])
		result = dashboard.rep_figures(
			"_Test Company",
			dashboard.resolve_period("this_month", getdate(nowdate()), "_Test Company"),
			"nobody@example.com",
		)
		self.assertFalse(result["linked"])
		self.assertEqual(result["kpis"]["my_sales"]["value"], 0)
		self.assertEqual(result["pipeline"]["open_quotes"]["count"], 0)
