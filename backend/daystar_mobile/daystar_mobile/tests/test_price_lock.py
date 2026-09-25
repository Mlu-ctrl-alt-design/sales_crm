"""A Mobile Sales Rep cannot move a price off the Price List, even via the API.

The HTTP tests go through the real REST endpoints with the rep's API token,
which is exactly how a tampered request from a device would arrive.
"""

import json

import frappe
from frappe.tests import IntegrationTestCase
from frappe.tests.test_api import FrappeAPITestCase
from frappe.utils import nowdate

from daystar_mobile.permissions import MOBILE_SALES_REP

REP = "dm-test-rep@example.com"
OWNER = "dm-test-owner@example.com"
CUSTOMER = "_Test DM Customer"
ITEM = "_Test DM Item"
PRICE_LIST = "Standard Selling"
LIST_RATE = 100.0

# Master data a rep must read to raise a quote or invoice. Which masters the
# real Mobile Sales Rep role may see, and scoped how, is Phase 5 (rep scoping);
# until then the test rep gets them through this test-only role, so the
# Mobile Sales Rep role itself stays minimal.
LOOKUP_ROLE = "_Test DM Lookup"
LOOKUP_DOCTYPES = ("Customer", "Account", "Item")


def setup_fixtures():
	"""Committed, idempotent fixtures (API requests run on their own connection)."""
	company = (
		frappe.db.get_single_value("Global Defaults", "default_company")
		or frappe.get_all("Company", pluck="name", limit=1)[0]
	)

	if not frappe.db.exists("Customer", CUSTOMER):
		frappe.get_doc(
			{
				"doctype": "Customer",
				"customer_name": CUSTOMER,
				"customer_group": frappe.get_all("Customer Group", {"is_group": 0}, pluck="name", limit=1)[0],
				"territory": frappe.get_all("Territory", {"is_group": 0}, pluck="name", limit=1)[0],
			}
		).insert(ignore_permissions=True)

	if not frappe.db.exists("Item", ITEM):
		frappe.get_doc(
			{
				"doctype": "Item",
				"item_code": ITEM,
				"item_group": frappe.get_all("Item Group", {"is_group": 0}, pluck="name", limit=1)[0],
				"stock_uom": "Nos",
				"is_stock_item": 0,
			}
		).insert(ignore_permissions=True)

	if not frappe.db.exists("Item Price", {"item_code": ITEM, "price_list": PRICE_LIST}):
		frappe.get_doc(
			{
				"doctype": "Item Price",
				"item_code": ITEM,
				"price_list": PRICE_LIST,
				"price_list_rate": LIST_RATE,
			}
		).insert(ignore_permissions=True)

	make_lookup_role()
	make_user(REP, [MOBILE_SALES_REP, LOOKUP_ROLE])
	make_user(OWNER, ["Sales User", "Accounts User"])
	frappe.db.commit()
	return company


def make_lookup_role():
	from frappe.permissions import add_permission

	if not frappe.db.exists("Role", LOOKUP_ROLE):
		frappe.get_doc({"doctype": "Role", "role_name": LOOKUP_ROLE, "desk_access": 0}).insert()
	for doctype in LOOKUP_DOCTYPES:
		if not frappe.db.exists("Custom DocPerm", {"parent": doctype, "role": LOOKUP_ROLE}):
			add_permission(doctype, LOOKUP_ROLE, 0, "read")


def make_user(email, roles):
	if frappe.db.exists("User", email):
		user = frappe.get_doc("User", email)
	else:
		user = frappe.get_doc(
			{"doctype": "User", "email": email, "first_name": email.split("@")[0], "send_welcome_email": 0}
		).insert(ignore_permissions=True)
	user.set("roles", [])
	user.add_roles(*roles)
	return user


def api_token(user):
	from frappe.core.doctype.user.user import generate_keys

	secret = generate_keys(user)["api_secret"]
	frappe.db.commit()
	return f"token {frappe.db.get_value('User', user, 'api_key')}:{secret}"


def quotation_payload(company, rate=LIST_RATE, docstatus=0, **item_overrides):
	item = {"item_code": ITEM, "qty": 2, "rate": rate, **item_overrides}
	return {
		"doctype": "Quotation",
		"quotation_to": "Customer",
		"party_name": CUSTOMER,
		"company": company,
		"transaction_date": nowdate(),
		"selling_price_list": PRICE_LIST,
		"items": [item],
		"docstatus": docstatus,
	}


class TestPriceLockAPI(FrappeAPITestCase):
	@classmethod
	def setUpClass(cls):
		super().setUpClass()
		cls.company = setup_fixtures()
		cls.rep_auth = {"Authorization": api_token(REP)}

	def tearDown(self):
		frappe.db.rollback()
		frappe.db.delete("Quotation", {"party_name": CUSTOMER})
		frappe.db.delete("Quotation Item", {"item_code": ITEM})
		frappe.db.commit()
		super().tearDown()

	def post_quotation(self, payload):
		return self.post(self.resource("Quotation"), payload, headers=self.rep_auth)

	def assert_price_locked(self, response):
		self.assertNotEqual(response.status_code, 200, response.json)
		self.assertIn("Price locked", json.dumps(response.json))

	def test_rep_can_submit_at_price_list_rate(self):
		# Positive control: the rep has enough rights that a rejection below
		# really comes from the price lock, not from a missing permission.
		response = self.post_quotation(quotation_payload(self.company, docstatus=1))
		self.assertEqual(response.status_code, 200, response.json)
		self.assertEqual(response.json["data"]["docstatus"], 1)
		self.assertEqual(response.json["data"]["items"][0]["rate"], LIST_RATE)

	def test_rep_cannot_submit_quotation_with_modified_rate(self):
		response = self.post_quotation(quotation_payload(self.company, rate=80, docstatus=1))
		self.assert_price_locked(response)
		self.assertFalse(frappe.db.exists("Quotation", {"party_name": CUSTOMER}))

	def test_rep_cannot_save_draft_with_modified_rate(self):
		response = self.post_quotation(quotation_payload(self.company, rate=120))
		self.assert_price_locked(response)
		self.assertFalse(frappe.db.exists("Quotation", {"party_name": CUSTOMER}))

	def test_rep_cannot_discount(self):
		response = self.post_quotation(
			quotation_payload(self.company, rate=90, discount_percentage=10, price_list_rate=LIST_RATE)
		)
		self.assert_price_locked(response)

		payload = quotation_payload(self.company)
		payload["additional_discount_percentage"] = 10
		self.assert_price_locked(self.post_quotation(payload))

	def test_rep_rate_edit_on_existing_draft_is_ignored(self):
		# The permlevel layer: on an existing document the rep's write to a
		# locked field is reset to the stored value, then the lock passes.
		created = self.post_quotation(quotation_payload(self.company))
		self.assertEqual(created.status_code, 200, created.json)
		doc = created.json["data"]
		doc["items"][0]["rate"] = 50
		doc["docstatus"] = 1

		response = self.put(self.resource("Quotation", doc["name"]), doc, headers=self.rep_auth)

		self.assertEqual(response.status_code, 200, response.json)
		self.assertEqual(frappe.db.get_value("Quotation Item", {"parent": doc["name"]}, "rate"), LIST_RATE)

	def test_owner_can_override_rate(self):
		owner_auth = {"Authorization": api_token(OWNER)}
		response = self.post(
			self.resource("Quotation"),
			quotation_payload(self.company, rate=80, docstatus=1),
			headers=owner_auth,
		)
		self.assertEqual(response.status_code, 200, response.json)
		self.assertEqual(response.json["data"]["items"][0]["rate"], 80)


class TestPriceLockSalesInvoice(IntegrationTestCase):
	@classmethod
	def setUpClass(cls):
		super().setUpClass()
		cls.company = setup_fixtures()

	def make_invoice(self, rate):
		return frappe.get_doc(
			{
				"doctype": "Sales Invoice",
				"customer": CUSTOMER,
				"company": self.company,
				"posting_date": nowdate(),
				"selling_price_list": PRICE_LIST,
				"items": [{"item_code": ITEM, "qty": 1, "rate": rate}],
			}
		)

	def test_rep_cannot_invoice_with_modified_rate(self):
		with self.set_user(REP):
			with self.assertRaisesRegex(frappe.PermissionError, "must be"):
				self.make_invoice(rate=1).insert()

	def test_rep_can_invoice_at_price_list_rate(self):
		with self.set_user(REP):
			invoice = self.make_invoice(rate=LIST_RATE).insert()
		self.assertEqual(invoice.items[0].rate, LIST_RATE)

	def test_item_without_price_is_rejected_for_rep(self):
		invoice = self.make_invoice(rate=LIST_RATE)
		invoice.selling_price_list = (
			frappe.get_doc(
				{
					"doctype": "Price List",
					"price_list_name": "_Test DM Empty",
					"selling": 1,
					"currency": "INR",
				}
			)
			.insert(ignore_if_duplicate=True)
			.name
		)
		with self.set_user(REP):
			with self.assertRaisesRegex(frappe.PermissionError, "has no price"):
				invoice.insert()


class TestPriceLockPermissions(IntegrationTestCase):
	def test_only_the_rep_role_loses_write_on_prices(self):
		from daystar_mobile.price_lock import PRICE_LOCK_PERMLEVEL, PRICE_LOCKED_DOCTYPES, _doctype_perms

		for doctype in PRICE_LOCKED_DOCTYPES:
			perms = _doctype_perms(doctype)
			level0_writers = {p.role for p in perms if p.permlevel == 0 and p.write}
			locked_writers = {p.role for p in perms if p.permlevel == PRICE_LOCK_PERMLEVEL and p.write}
			locked_readers = {p.role for p in perms if p.permlevel == PRICE_LOCK_PERMLEVEL and p.read}

			self.assertEqual(locked_writers, level0_writers - {MOBILE_SALES_REP}, doctype)
			self.assertIn(MOBILE_SALES_REP, locked_readers, doctype)

	def test_rate_and_discount_fields_are_locked(self):
		from daystar_mobile.price_lock import PRICE_LOCK_PERMLEVEL

		for child in ("Quotation Item", "Sales Invoice Item"):
			meta = frappe.get_meta(child)
			for fieldname in ("rate", "discount_percentage"):
				self.assertEqual(
					meta.get_field(fieldname).permlevel, PRICE_LOCK_PERMLEVEL, f"{child}.{fieldname}"
				)
