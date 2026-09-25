"""Price List lock for the Mobile Sales Rep role.

Two layers, per the spec:

1. `rate` and `discount_percentage` on Quotation Item and Sales Invoice Item
   sit at PRICE_LOCK_PERMLEVEL (Property Setter fixtures). Every role that can
   write the parent keeps write at that level; the rep role only gets read.
2. A `validate` hook rejects any row whose rate differs from the Price List.

Layer 1 alone is not enough: Frappe skips the permlevel reset for child rows
of a new document, so a direct API insert could still carry a tampered rate.
"""

import frappe
from frappe import _
from frappe.permissions import add_permission, update_permission_property
from frappe.utils import flt

from daystar_mobile.permissions import MOBILE_SALES_REP, is_mobile_sales_rep

# A level no standard or Daystar field uses, so the lock is not entangled with
# existing level-1 fields (e.g. Quotation.ignore_pricing_rule).
PRICE_LOCK_PERMLEVEL = 2
PRICE_LOCKED_DOCTYPES = ("Quotation", "Sales Invoice")

# What the rep role may do with its own quotes and invoices at level 0.
# Row-level scoping by Sales Team comes with the Phase 5 permission hooks.
REP_LEVEL0_RIGHTS = ("read", "write", "create", "submit", "print", "email")


def validate_price_list_rates(doc, method=None):
	"""doc_events validate hook for Quotation and Sales Invoice."""
	if not is_mobile_sales_rep():
		return

	if flt(doc.get("additional_discount_percentage")) or flt(doc.get("discount_amount")):
		frappe.throw(
			_("Discounts are locked to the Price List. Ask the owner to apply a discount."),
			frappe.PermissionError,
			title=_("Price locked"),
		)

	for item in doc.get("items"):
		expected = get_expected_rate(doc, item)
		if expected is None:
			frappe.throw(
				_("Row {0}: {1} has no price in Price List {2}. Ask the owner to price it.").format(
					item.idx, frappe.bold(item.item_code), frappe.bold(doc.selling_price_list)
				),
				frappe.PermissionError,
				title=_("Price locked"),
			)

		precision = item.precision("rate")
		if flt(item.rate, precision) != flt(expected, precision):
			frappe.throw(
				_(
					"Row {0}: rate for {1} must be {2} from Price List {3}. Ask the owner to change prices."
				).format(
					item.idx,
					frappe.bold(item.item_code),
					frappe.format(expected, {"fieldtype": "Currency", "options": doc.currency}),
					frappe.bold(doc.selling_price_list),
				),
				frappe.PermissionError,
				title=_("Price locked"),
			)

		# Checked after the rate: ERPNext derives discount_amount from a
		# lowered rate, and the rate message is the clearer one.
		if flt(item.discount_percentage) or flt(item.discount_amount):
			frappe.throw(
				_(
					"Row {0}: discounts are locked to the Price List. Ask the owner to apply a discount."
				).format(item.idx),
				frappe.PermissionError,
				title=_("Price locked"),
			)


def get_expected_rate(doc, item) -> float | None:
	"""Price List rate for the row, in the document's currency and the row's UOM.

	Uses ERPNext's own lookup so customer-specific prices, validity dates and
	UOM conversion match what the form would have filled in.
	"""
	from erpnext.stock.get_item_details import get_price_list_rate_for

	if not doc.selling_price_list or not item.item_code:
		return None

	customer = doc.get("customer") or (
		doc.get("party_name") if doc.get("quotation_to") == "Customer" else None
	)
	ctx = frappe._dict(
		price_list=doc.selling_price_list,
		customer=customer,
		uom=item.uom,
		stock_uom=item.stock_uom,
		conversion_factor=item.conversion_factor or 1,
		qty=item.qty,
		transaction_date=doc.get("transaction_date") or doc.get("posting_date"),
		batch_no=item.get("batch_no"),
	)
	rate = get_price_list_rate_for(ctx, item.item_code)
	if rate is None or rate == 0:
		# get_price_list_rate_for returns 0 when nothing matched
		return None

	return flt(rate) * flt(doc.plc_conversion_rate or 1) / flt(doc.conversion_rate or 1)


def setup_price_lock_permissions():
	"""Grant PRICE_LOCK_PERMLEVEL access so only the rep role is locked.

	Idempotent and additive: it never removes or edits existing rows at other
	levels. Runs after install and after every migrate so roles given write
	access later also keep the right to edit prices.
	"""
	for doctype in PRICE_LOCKED_DOCTYPES:
		_ensure_rep_level0(doctype)

		perms = _doctype_perms(doctype)
		writers = {p.role for p in perms if p.permlevel == 0 and p.write and p.role != MOBILE_SALES_REP}
		readers = {p.role for p in perms if p.permlevel == 0 and p.read}

		for role in readers:
			_ensure_perm(doctype, role, PRICE_LOCK_PERMLEVEL, "read")
		for role in writers:
			_ensure_perm(doctype, role, PRICE_LOCK_PERMLEVEL, "write")


def _doctype_perms(doctype):
	"""Effective permission rows: Custom DocPerm if customised, else DocPerm."""
	if frappe.db.exists("Custom DocPerm", {"parent": doctype}):
		return frappe.get_all("Custom DocPerm", filters={"parent": doctype}, fields=["*"])
	return frappe.get_all("DocPerm", filters={"parent": doctype}, fields=["*"])


def _ensure_rep_level0(doctype):
	for right in REP_LEVEL0_RIGHTS:
		_ensure_perm(doctype, MOBILE_SALES_REP, 0, right)


def _ensure_perm(doctype, role, permlevel, right):
	name = frappe.db.get_value(
		"Custom DocPerm", {"parent": doctype, "role": role, "permlevel": permlevel, "if_owner": 0}
	)
	if not name:
		add_permission(doctype, role, permlevel, right)
		return
	if not frappe.db.get_value("Custom DocPerm", name, right):
		update_permission_property(doctype, role, permlevel, right, 1, validate=False)
