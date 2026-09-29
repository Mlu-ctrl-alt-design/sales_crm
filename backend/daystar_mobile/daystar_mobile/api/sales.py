"""The sales process on the phone: lead → opportunity → quote → invoice.

Each step is ERPNext's own converter (`make_opportunity`, `make_customer`,
`make_sales_invoice`), so fields map exactly as the Desk buttons map them.
Quotes themselves are built by `documents.submit`, with the opportunity
linked, so they keep the Price List rules of the quick-send screen.

Everything runs as the session user; ERPNext's permissions decide what
they may see and do. Leads are Daystar's or have no company at all (n8n
and web-form leads land without one); the legacy company is never shown.
"""

import hashlib

import frappe
from frappe import _
from frappe.utils import cint, flt, getdate, nowdate
from frappe.utils.data import escape_html

from daystar_mobile.api.documents import SEARCH_LIMIT, _limit, _submitted
from daystar_mobile.scope import get_company

OPEN_LEAD_STATUSES = ("Lead", "Open", "Replied", "Interested", "Opportunity", "Quotation")
OPEN_OPPORTUNITY_STATUSES = ("Open", "Replied", "Quotation")

LEAD_FILTERS = ("open", "mine", "unassigned", "all")
OPPORTUNITY_FILTERS = ("open", "mine", "all")

KEY_FIELD = "daystar_mobile_key"


# Leads


@frappe.whitelist(methods=["GET"])
def list_leads(txt: str | None = None, filter: str = "open", limit: int = SEARCH_LIMIT):
	"""Leads matching `txt`, newest first.

	`filter`: open (not converted or dead), mine (open and mine), unassigned
	(open, no owner), all.
	"""
	if filter not in LEAD_FILTERS:
		frappe.throw(_("Unknown lead filter."))

	filters = [["company", "in", ["", get_company()]]]
	if filter != "all":
		filters.append(["status", "in", OPEN_LEAD_STATUSES])
	if filter == "mine":
		filters.append(["lead_owner", "=", frappe.session.user])
	elif filter == "unassigned":
		filters.append(["lead_owner", "is", "not set"])

	txt = (txt or "").strip()
	or_filters = None
	if txt:
		like = f"%{txt}%"
		or_filters = {
			field: ["like", like] for field in ("name", "lead_name", "company_name", "email_id", "mobile_no")
		}

	rows = frappe.get_list(
		"Lead",
		filters=filters,
		or_filters=or_filters,
		fields=[
			"name",
			"lead_name",
			"company_name",
			"email_id",
			"mobile_no",
			"status",
			"lead_owner",
			"creation",
		],
		order_by="creation desc",
		limit_page_length=_limit(limit),
	)
	return [_lead_row(row) for row in rows]


@frappe.whitelist(methods=["GET"])
def get_lead(name: str):
	"""A lead with what it has become: its opportunities and customer."""
	lead = _get_lead(name)
	customer = _customer_for_lead(lead.name)
	opportunities = frappe.get_list(
		"Opportunity",
		filters={"opportunity_from": "Lead", "party_name": lead.name, "company": get_company()},
		fields=_OPPORTUNITY_FIELDS,
		order_by="creation desc",
		limit_page_length=20,
	)
	return {
		**_lead_row(lead),
		"first_name": lead.first_name,
		"last_name": lead.last_name,
		"phone": lead.phone,
		"website": lead.website,
		"city": lead.city,
		"source": lead.get("utm_source") or lead.get("source"),
		"notes": _latest_note(lead),
		"customer": customer,
		"opportunities": [_opportunity_row(row) for row in opportunities],
		"can_convert": bool(frappe.has_permission("Opportunity", "create")),
	}


@frappe.whitelist(methods=["POST"])
def create_lead(
	first_name: str,
	last_name: str | None = None,
	mobile_no: str | None = None,
	email_id: str | None = None,
	company_name: str | None = None,
	notes: str | None = None,
):
	"""A new Daystar lead, owned by whoever captured it."""
	frappe.has_permission("Lead", "create", throw=True)
	first_name = (first_name or "").strip()
	if not first_name:
		frappe.throw(_("Add the lead's first name."))
	if not (mobile_no or "").strip() and not (email_id or "").strip():
		frappe.throw(_("Add a mobile number or an email address, so you can reach them."))

	lead = frappe.new_doc("Lead")
	lead.update(
		{
			"first_name": first_name,
			"last_name": (last_name or "").strip() or None,
			"mobile_no": (mobile_no or "").strip() or None,
			"email_id": (email_id or "").strip() or None,
			"company_name": (company_name or "").strip() or None,
			"company": get_company(),
			"lead_owner": frappe.session.user,
		}
	)
	if (notes or "").strip():
		lead.append("notes", {"note": escape_html(notes.strip()), "added_by": frappe.session.user})
	lead.insert()
	return get_lead(lead.name)


@frappe.whitelist(methods=["POST"])
def lead_to_opportunity(lead: str, amount: float | None = None, expected_closing: str | None = None):
	"""ERPNext's Lead → Opportunity, saved, in Daystar."""
	from erpnext.crm.doctype.lead.lead import make_opportunity

	_get_lead(lead)
	frappe.has_permission("Opportunity", "create", throw=True)

	opportunity = make_opportunity(lead)
	opportunity.company = get_company()
	opportunity.opportunity_owner = opportunity.opportunity_owner or frappe.session.user
	_set_value_and_closing(opportunity, amount, expected_closing)
	opportunity.insert()
	return get_opportunity(opportunity.name)


# Opportunities


_OPPORTUNITY_FIELDS = [
	"name",
	"opportunity_from",
	"party_name",
	"customer_name",
	"title",
	"status",
	"sales_stage",
	"opportunity_amount",
	"currency",
	"expected_closing",
	"opportunity_owner",
	"creation",
]


@frappe.whitelist(methods=["GET"])
def list_opportunities(txt: str | None = None, filter: str = "open", limit: int = SEARCH_LIMIT):
	"""Daystar opportunities matching `txt`, newest first."""
	if filter not in OPPORTUNITY_FILTERS:
		frappe.throw(_("Unknown opportunity filter."))

	filters = [["company", "=", get_company()]]
	if filter != "all":
		filters.append(["status", "in", OPEN_OPPORTUNITY_STATUSES])
	if filter == "mine":
		filters.append(["opportunity_owner", "=", frappe.session.user])

	txt = (txt or "").strip()
	or_filters = None
	if txt:
		like = f"%{txt}%"
		or_filters = {field: ["like", like] for field in ("name", "party_name", "customer_name", "title")}

	rows = frappe.get_list(
		"Opportunity",
		filters=filters,
		or_filters=or_filters,
		fields=_OPPORTUNITY_FIELDS,
		order_by="creation desc",
		limit_page_length=_limit(limit),
	)
	return [_opportunity_row(row) for row in rows]


@frappe.whitelist(methods=["GET"])
def get_opportunity(name: str):
	"""An opportunity with its customer (if there is one yet) and its quotes."""
	opportunity = _get_opportunity(name)
	quotes = frappe.get_list(
		"Quotation",
		filters={"opportunity": opportunity.name, "docstatus": ["<", 2]},
		fields=["name", "status", "docstatus", "transaction_date", "grand_total", "rounded_total", "currency"],
		order_by="creation desc",
		limit_page_length=20,
	)
	return {
		**_opportunity_row(opportunity),
		"contact_email": opportunity.contact_email,
		"contact_mobile": opportunity.contact_mobile,
		"notes": _latest_note(opportunity),
		"customer": _customer_for_opportunity(opportunity),
		"quotes": [_quote_row(row) for row in quotes],
	}


@frappe.whitelist(methods=["POST"])
def create_opportunity(
	customer: str,
	amount: float | None = None,
	expected_closing: str | None = None,
	notes: str | None = None,
):
	"""A new opportunity with an existing customer."""
	frappe.has_permission("Opportunity", "create", throw=True)
	frappe.has_permission("Customer", doc=customer, throw=True)

	opportunity = frappe.new_doc("Opportunity")
	opportunity.update(
		{
			"opportunity_from": "Customer",
			"party_name": customer,
			"company": get_company(),
			"transaction_date": nowdate(),
			"opportunity_owner": frappe.session.user,
		}
	)
	_set_value_and_closing(opportunity, amount, expected_closing)
	if (notes or "").strip():
		opportunity.append("notes", {"note": escape_html(notes.strip()), "added_by": frappe.session.user})
	opportunity.insert()
	return get_opportunity(opportunity.name)


# Customers


@frappe.whitelist(methods=["POST"])
def create_customer(
	customer_name: str,
	customer_type: str = "Company",
	email_id: str | None = None,
	mobile_no: str | None = None,
):
	"""A new customer. ERPNext makes the primary contact from the email and mobile."""
	frappe.has_permission("Customer", "create", throw=True)
	customer_name = (customer_name or "").strip()
	if not customer_name:
		frappe.throw(_("Add the customer's name."))
	if customer_type not in ("Company", "Individual"):
		frappe.throw(_("A customer is a company or an individual."))

	customer = frappe.new_doc("Customer")
	customer.update(
		{
			"customer_name": customer_name,
			"customer_type": customer_type,
			"email_id": (email_id or "").strip() or None,
			"mobile_no": (mobile_no or "").strip() or None,
		}
	)
	_default_groups(customer)
	customer.insert()
	return _customer_row(customer)


@frappe.whitelist(methods=["POST"])
def make_customer(lead: str | None = None, opportunity: str | None = None):
	"""The customer for a lead or opportunity, created with ERPNext's converter
	the first time and returned as-is after that. Converting marks the lead
	Converted."""
	if bool(lead) == bool(opportunity):
		frappe.throw(_("Choose a lead or an opportunity."))

	if opportunity:
		doc = _get_opportunity(opportunity)
		if existing := _customer_for_opportunity(doc):
			return existing
		if doc.opportunity_from != "Lead":
			frappe.throw(_("This opportunity isn't with a lead or a customer."))
		lead = doc.party_name

	_get_lead(lead)
	if existing := _customer_for_lead(lead):
		return existing

	from erpnext.crm.doctype.lead.lead import make_customer as lead_to_customer

	frappe.has_permission("Customer", "create", throw=True)
	customer = lead_to_customer(lead)
	if opportunity:
		customer.opportunity_name = opportunity
	_default_groups(customer)
	customer.insert()
	return _customer_row(customer)


# Quote → invoice


@frappe.whitelist(methods=["POST"])
def quote_to_invoice(quotation: str):
	"""ERPNext's Quotation → Sales Invoice, submitted, once per quote.

	The invoice is keyed on the quotation, so a retry after a lost answer
	returns the invoice the first attempt made instead of making another.
	The price lock applies as it does to any invoice.
	"""
	from erpnext.selling.doctype.quotation.quotation import make_sales_invoice

	quote = frappe.get_doc("Quotation", quotation)
	quote.check_permission("read")
	if quote.company != get_company():
		frappe.throw(_("{0} isn't a Daystar quotation.").format(quotation), frappe.PermissionError)
	if quote.docstatus != 1:
		frappe.throw(_("Submit the quotation before invoicing it."))
	if quote.quotation_to != "Customer":
		frappe.throw(_("Make {0} a customer before invoicing this quote.").format(quote.customer_name))

	key = invoice_key(quote.name)
	if existing := _invoice_for_key(key):
		if existing.docstatus == 2:
			frappe.throw(
				_("{0} from this quote was cancelled. Raise a new invoice from Quick send.").format(
					existing.name
				)
			)
		return _submitted(existing)

	frappe.has_permission("Sales Invoice", "create", throw=True)
	invoice = make_sales_invoice(quote.name)
	invoice.set(KEY_FIELD, key)
	try:
		invoice.insert()
		invoice.submit()
	except frappe.UniqueValidationError:
		# A concurrent retry won the race.
		frappe.db.rollback()
		frappe.clear_messages()
		if existing := _invoice_for_key(key):
			return _submitted(existing)
		raise
	return _submitted(invoice)


@frappe.whitelist(methods=["GET"])
def quote_invoice(quotation: str):
	"""The invoice made from this quote in the app, if any: `{name, docstatus}` or null."""
	quote = frappe.get_doc("Quotation", quotation)
	quote.check_permission("read")
	invoice = _invoice_for_key(invoice_key(quote.name))
	return {"name": invoice.name, "docstatus": invoice.docstatus} if invoice else None


def invoice_key(quotation: str) -> str:
	"""The idempotency key of the invoice made from `quotation`."""
	return "quote-" + hashlib.sha1(quotation.encode()).hexdigest()[:32]


# Helpers


def _get_lead(name: str):
	lead = frappe.get_doc("Lead", name)
	lead.check_permission("read")
	if lead.company and lead.company != get_company():
		frappe.throw(_("{0} isn't a Daystar lead.").format(name), frappe.PermissionError)
	return lead


def _get_opportunity(name: str):
	opportunity = frappe.get_doc("Opportunity", name)
	opportunity.check_permission("read")
	if opportunity.company != get_company():
		frappe.throw(_("{0} isn't a Daystar opportunity.").format(name), frappe.PermissionError)
	return opportunity


def _customer_for_lead(lead: str) -> dict | None:
	names = frappe.get_list("Customer", filters={"lead_name": lead}, pluck="name", limit_page_length=1)
	return _customer_row(frappe.get_doc("Customer", names[0])) if names else None


def _customer_for_opportunity(opportunity) -> dict | None:
	if opportunity.opportunity_from == "Customer":
		if not frappe.has_permission("Customer", doc=opportunity.party_name):
			return None
		return _customer_row(frappe.get_doc("Customer", opportunity.party_name))
	if opportunity.opportunity_from == "Lead":
		return _customer_for_lead(opportunity.party_name)
	return None


def _customer_row(customer) -> dict:
	"""Shaped like `documents.search_customers`, so the quick-send draft takes it."""
	return {
		"name": customer.name,
		"customer_name": customer.customer_name,
		"email_id": customer.email_id,
		"mobile_no": customer.mobile_no,
	}


def _default_groups(customer):
	"""Selling Settings' defaults, as the Customer form fills them in."""
	for field, setting, doctype in (
		("customer_group", "customer_group", "Customer Group"),
		("territory", "territory", "Territory"),
	):
		if not customer.get(field):
			customer.set(
				field,
				frappe.db.get_single_value("Selling Settings", setting)
				or frappe.db.get_value(doctype, {"is_group": 0}, "name"),
			)


def _set_value_and_closing(opportunity, amount, expected_closing):
	if amount not in (None, ""):
		if flt(amount) < 0:
			frappe.throw(_("The value can't be negative."))
		opportunity.opportunity_amount = flt(amount)
	if expected_closing:
		opportunity.expected_closing = getdate(expected_closing)


def _latest_note(doc) -> str | None:
	notes = doc.get("notes") or []
	if not notes:
		return None
	from frappe.utils import strip_html

	return strip_html(notes[-1].note or "").strip() or None


def _lead_row(row) -> dict:
	return {
		"name": row.name,
		"lead_name": row.lead_name,
		"company_name": row.company_name,
		"email_id": row.email_id,
		"mobile_no": row.mobile_no,
		"status": row.status,
		"lead_owner": row.lead_owner,
		"created": str(getdate(row.creation)),
	}


def _opportunity_row(row) -> dict:
	return {
		"name": row.name,
		"opportunity_from": row.opportunity_from,
		"party_name": row.party_name,
		"title": row.title or row.customer_name or row.party_name,
		"status": row.status,
		"sales_stage": row.sales_stage,
		"amount": flt(row.opportunity_amount),
		"currency": row.currency,
		"expected_closing": str(row.expected_closing) if row.expected_closing else None,
		"opportunity_owner": row.opportunity_owner,
		"created": str(getdate(row.creation)),
	}


def _quote_row(row) -> dict:
	return {
		"name": row.name,
		"status": row.status,
		"submitted": cint(row.docstatus) == 1,
		"date": str(row.transaction_date),
		"currency": row.currency,
		"total": row.rounded_total or row.grand_total,
	}


def _invoice_for_key(key: str):
	names = frappe.get_list(
		"Sales Invoice", filters={KEY_FIELD: key}, pluck="name", limit_page_length=1
	)
	return frappe.get_doc("Sales Invoice", names[0]) if names else None
