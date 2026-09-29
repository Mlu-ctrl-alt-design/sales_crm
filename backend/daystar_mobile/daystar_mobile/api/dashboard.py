"""Owner and rep dashboard KPIs (Phase 3).

One endpoint, two views, chosen by what the session user may see:

- owner: may open the Profit and Loss Statement and Accounts Receivable
  reports. Profit and receivables come from running those reports, so the
  figures match Desk to the cent.
- rep: everyone else. Totals for their own work only (Sales Team, lead and
  opportunity owner); never profit, suppliers or money paid out.

Every figure comes with the same measure for the comparable stretch of the
previous period (1-27 Sep against 1-27 Aug), so the app can show a change.
Only the app's company (`scope.get_company`) is ever counted.
"""

import re
from datetime import date

import frappe
from frappe import _
from frappe.query_builder.functions import Count, IfNull, Sum
from frappe.utils import add_days, add_months, flt, get_first_day, get_last_day, getdate, nowdate

from daystar_mobile.scope import get_company

PERIODS = ("this_month", "last_month", "this_quarter", "this_fy")
# Any whole month, e.g. "month:2026-07".
_MONTH = re.compile(r"^month:(\d{4})-(\d{2})$")
OWNER_REPORTS = ("Profit and Loss Statement", "Accounts Receivable")
CACHE_SECONDS = 300

OPEN_LEAD_STATUSES = ("Lead", "Open", "Replied", "Interested")
OPEN_OPPORTUNITY_STATUSES = ("Open", "Replied")
OPEN_QUOTE_STATUSES = ("Open", "Replied")


@frappe.whitelist(methods=["GET"])
def get(period: str = "this_month", refresh: int = 0):
	if period not in PERIODS and not _MONTH.match(period or ""):
		frappe.throw(_("Unknown period."), frappe.ValidationError)

	company = get_company()
	span = resolve_period(period, getdate(nowdate()), company)

	if is_owner():
		key = f"daystar_mobile:dashboard:owner:{company}:{period}:{span['to']}"
		data = None if int(refresh or 0) else frappe.cache.get_value(key)
		if data is None:
			data = owner_figures(company, span)
			frappe.cache.set_value(key, data, expires_in_sec=CACHE_SECONDS)
	else:
		data = rep_figures(company, span, frappe.session.user)

	return {
		"company": company,
		"currency": frappe.get_cached_value("Company", company, "default_currency"),
		"period": _period_json(period, span),
		**data,
	}


def is_owner() -> bool:
	"""The session user may see company-wide money.

	They must be able to open both source reports and read the General
	Ledger; a report with no roles set would otherwise let anyone in.
	"""
	return frappe.has_permission("GL Entry", "read") and all(
		frappe.get_cached_doc("Report", name).is_permitted() for name in OWNER_REPORTS
	)


# Periods
# -------


def resolve_period(period: str, today: date, company: str) -> dict:
	"""The period's dates and the comparable dates before it.

	Periods to date compare with the same stretch of the previous period;
	last month compares with the whole month before. Quarters and years are
	fiscal, as the P&L report's periods are. A chosen month ("month:2026-07")
	compares with the whole month before it; the current month runs to date,
	as "this_month" does.
	"""
	if match := _MONTH.match(period):
		year, month = int(match[1]), int(match[2])
		if not 1 <= month <= 12:
			frappe.throw(_("Unknown period."), frappe.ValidationError)
		start = date(year, month, 1)
		if start > today:
			frappe.throw(_("That month hasn't started yet."), frappe.ValidationError)
		if start == get_first_day(today):
			period = "this_month"
		else:
			prev_start = add_months(start, -1)
			return _span(start, get_last_day(start), prev_start, get_last_day(prev_start))

	if period == "this_month":
		start, end = get_first_day(today), today
		return _span(start, end, add_months(start, -1), add_months(end, -1))

	if period == "last_month":
		start = get_first_day(add_months(today, -1))
		end = get_last_day(start)
		prev_start = add_months(start, -1)
		return _span(start, end, prev_start, get_last_day(prev_start))

	fy_start = _fiscal_year_start(today, company)
	if period == "this_quarter":
		months_in = (today.year - fy_start.year) * 12 + today.month - fy_start.month
		start = add_months(fy_start, months_in // 3 * 3)
		prev_start = add_months(start, -3)
		return _span(start, today, prev_start, min(add_months(today, -3), add_days(start, -1)))

	prev_start = _fiscal_year_start(add_days(fy_start, -1), company)
	return _span(fy_start, today, prev_start, min(add_months(today, -12), add_days(fy_start, -1)))


def _span(start, end, prev_start, prev_end) -> dict:
	return {
		"from": getdate(start),
		"to": getdate(end),
		"prev_from": getdate(prev_start),
		"prev_to": getdate(prev_end),
	}


def _fiscal_year_start(day, company) -> date:
	from erpnext.accounts.utils import get_fiscal_year

	return getdate(get_fiscal_year(day, company=company)[1])


def _period_json(period: str, span: dict) -> dict:
	return {
		"key": period,
		"from": str(span["from"]),
		"to": str(span["to"]),
		"previous_from": str(span["prev_from"]),
		"previous_to": str(span["prev_to"]),
	}


# Owner
# -----


def owner_figures(company: str, span: dict) -> dict:
	now, before = (span["from"], span["to"]), (span["prev_from"], span["prev_to"])
	receivable_now = receivables(company, span["to"])
	receivable_before = receivables(company, span["prev_to"])
	return {
		"view": "owner",
		"kpis": {
			"profit": _pair(profit(company, *now), profit(company, *before)),
			"sales": {
				**_pair(sales(company, *now), sales(company, *before)),
				"count": sales_count(company, *now),
			},
			"paid_out": _pair(paid_out(company, *now), paid_out(company, *before)),
			"receivables": {
				**_pair(receivable_now["outstanding"], receivable_before["outstanding"]),
				"overdue": receivable_now["overdue"],
			},
		},
		"pipeline": pipeline(company, span),
	}


def profit(company: str, from_date, to_date) -> float:
	"""Net profit exactly as the Profit and Loss Statement shows it for the dates."""
	from erpnext.accounts.report.profit_and_loss_statement.profit_and_loss_statement import execute

	filters = frappe._dict(
		company=company,
		filter_based_on="Date Range",
		period_start_date=str(from_date),
		period_end_date=str(to_date),
		periodicity="Yearly",
		accumulated_values=0,
		include_default_book_entries=1,
		presentation_currency=None,
	)
	result = execute(filters)
	if len(result) > 5:  # v15 also returns the net profit as a number
		return flt(result[5])
	net_row = next((row for row in reversed(result[1] or []) if row.get("warn_if_negative")), None)
	return flt(net_row.get("total")) if net_row else 0.0


def receivables(company: str, report_date) -> dict:
	"""Outstanding and overdue as the Accounts Receivable report shows them."""
	from erpnext.accounts.report.accounts_receivable.accounts_receivable import execute

	report_date = getdate(report_date)
	_columns, rows, *_ = execute(
		{
			"company": company,
			"report_date": report_date,
			"ageing_based_on": "Due Date",
			"age_as_on": "Report Date",
			"range": "30, 60, 90, 120",
		}
	)
	outstanding = overdue = 0.0
	for row in rows or []:
		amount = flt(row.get("outstanding"))
		outstanding += amount
		due = row.get("due_date")
		if amount > 0 and due and getdate(due) < report_date:
			overdue += amount
	return {"outstanding": flt(outstanding, 2), "overdue": flt(overdue, 2)}


def sales(company: str, from_date, to_date) -> float:
	"""Submitted Sales Invoices net of VAT, credit notes included (negative)."""
	invoice = frappe.qb.DocType("Sales Invoice")
	(value,) = (
		frappe.qb.from_(invoice)
		.select(Sum(invoice.base_net_total))
		.where(
			(invoice.company == company)
			& (invoice.docstatus == 1)
			& (invoice.posting_date[from_date:to_date])
		)
		.run()[0]
	)
	return flt(value)


def sales_count(company: str, from_date, to_date) -> int:
	return frappe.db.count(
		"Sales Invoice",
		{
			"company": company,
			"docstatus": 1,
			"is_return": 0,
			"posting_date": ["between", [from_date, to_date]],
		},
	)


def paid_out(company: str, from_date, to_date) -> float:
	"""Submitted Payment Entries of type Pay."""
	payment = frappe.qb.DocType("Payment Entry")
	(value,) = (
		frappe.qb.from_(payment)
		.select(Sum(payment.base_paid_amount))
		.where(
			(payment.company == company)
			& (payment.docstatus == 1)
			& (payment.payment_type == "Pay")
			& (payment.posting_date[from_date:to_date])
		)
		.run()[0]
	)
	return flt(value)


def pipeline(company: str, span: dict, owner: str | None = None, sales_persons=None) -> dict:
	"""Open leads, opportunities and quotes now, and new leads in the period.

	With `owner` / `sales_persons`, only that rep's: leads and opportunities
	they own, quotes where they're on the Sales Team.
	"""
	def new_leads(from_date, to_date):
		return _count_leads(
			company,
			owner,
			frappe.qb.DocType("Lead").creation[f"{from_date} 00:00:00" : f"{to_date} 23:59:59.999999"],
		)

	open_leads = _count_leads(company, owner, frappe.qb.DocType("Lead").status.isin(OPEN_LEAD_STATUSES))

	opportunity = frappe.qb.DocType("Opportunity")
	opp_query = (
		frappe.qb.from_(opportunity)
		.select(Count(opportunity.name), Sum(opportunity.base_opportunity_amount))
		.where(
			(opportunity.company == company)
			& (opportunity.status.isin(OPEN_OPPORTUNITY_STATUSES))
		)
	)
	if owner:
		opp_query = opp_query.where(opportunity.opportunity_owner == owner)
	opportunities = opp_query.run()[0]
	quotes = _open_quotes(company, sales_persons)

	return {
		"new_leads": _pair(
			new_leads(span["from"], span["to"]), new_leads(span["prev_from"], span["prev_to"])
		),
		"open_leads": open_leads,
		"open_opportunities": {"count": opportunities[0] or 0, "value": flt(opportunities[1])},
		"open_quotes": quotes,
	}


def _count_leads(company: str, owner: str | None, condition) -> int:
	"""Leads for the company, or with no company at all.

	Leads from n8n and web forms often carry no company; only the legacy
	company's leads are left out.
	"""
	lead = frappe.qb.DocType("Lead")
	query = (
		frappe.qb.from_(lead)
		.select(Count(lead.name))
		.where(IfNull(lead.company, "").isin(["", company]) & condition)
	)
	if owner:
		query = query.where(lead.lead_owner == owner)
	return query.run()[0][0] or 0


def _open_quotes(company: str, sales_persons=None) -> dict:
	quotation = frappe.qb.DocType("Quotation")
	query = (
		frappe.qb.from_(quotation)
		.select(Count(quotation.name), Sum(quotation.base_net_total))
		.where(
			(quotation.company == company)
			& (quotation.docstatus == 1)
			& (quotation.status.isin(OPEN_QUOTE_STATUSES))
		)
	)
	if sales_persons is not None:
		if not sales_persons:
			return {"count": 0, "value": 0.0}
		team = frappe.qb.DocType("Sales Team")
		query = query.where(
			quotation.name.isin(
				frappe.qb.from_(team)
				.select(team.parent)
				.where((team.parenttype == "Quotation") & (team.sales_person.isin(sales_persons)))
			)
		)
	count, value = query.run()[0]
	return {"count": count or 0, "value": flt(value)}


# Rep
# ---


def rep_figures(company: str, span: dict, user: str) -> dict:
	"""The rep's own totals. Never profit, suppliers or payments out."""
	persons = sales_persons_for(user)
	return {
		"view": "rep",
		"linked": bool(persons),
		"kpis": {
			"my_sales": _pair(
				_my_sales(company, persons, span["from"], span["to"]),
				_my_sales(company, persons, span["prev_from"], span["prev_to"]),
			),
			"my_outstanding": _my_outstanding(company, persons),
		},
		"pipeline": pipeline(company, span, owner=user, sales_persons=persons),
	}


def sales_persons_for(user: str) -> list[str]:
	"""Enabled Sales Persons linked to the user through their Employee record."""
	employees = frappe.get_all("Employee", filters={"user_id": user}, pluck="name")
	if not employees:
		return []
	return frappe.get_all("Sales Person", filters={"employee": ["in", employees], "enabled": 1}, pluck="name")


def _my_sales(company: str, persons: list[str], from_date, to_date) -> float:
	"""Their share of submitted invoices: the Sales Team's allocated amount."""
	if not persons:
		return 0.0
	invoice = frappe.qb.DocType("Sales Invoice")
	team = frappe.qb.DocType("Sales Team")
	(value,) = (
		frappe.qb.from_(team)
		.join(invoice)
		.on(team.parent == invoice.name)
		.select(Sum(team.allocated_amount))
		.where(
			(team.parenttype == "Sales Invoice")
			& (team.sales_person.isin(persons))
			& (invoice.company == company)
			& (invoice.docstatus == 1)
			& (invoice.posting_date[from_date:to_date])
		)
		.run()[0]
	)
	return flt(value)


def _my_outstanding(company: str, persons: list[str]) -> dict:
	"""What customers still owe on invoices the rep is on, and how much is overdue."""
	if not persons:
		return {"value": 0.0, "overdue": 0.0, "count": 0}
	invoice = frappe.qb.DocType("Sales Invoice")
	team = frappe.qb.DocType("Sales Team")
	mine = (
		frappe.qb.from_(team)
		.select(team.parent)
		.where((team.parenttype == "Sales Invoice") & (team.sales_person.isin(persons)))
	)
	today = getdate(nowdate())
	overdue_amount = (
		frappe.qb.terms.Case().when(invoice.due_date < today, invoice.outstanding_amount).else_(0)
	)
	count, value, overdue = (
		frappe.qb.from_(invoice)
		.select(
			Count(invoice.name),
			Sum(invoice.outstanding_amount),
			Sum(overdue_amount),
		)
		.where(
			(invoice.company == company)
			& (invoice.docstatus == 1)
			& (invoice.outstanding_amount > 0)
			& (invoice.name.isin(mine))
		)
		.run()[0]
	)
	return {"value": flt(value), "overdue": flt(overdue), "count": count or 0}


def _pair(value, previous) -> dict:
	return {"value": flt(value, 2), "previous": flt(previous, 2)}
