"""The sales process: lead → opportunity → quote → invoice, and customers."""

import uuid

import frappe
from frappe.tests import IntegrationTestCase

from daystar_mobile.api import documents, sales
from daystar_mobile.tests.test_price_lock import CUSTOMER, ITEM, OWNER, setup_fixtures

LEGACY_COMPANY = "_Test DM Legacy Company"


def unique(prefix: str) -> str:
	return f"{prefix} {uuid.uuid4().hex[:8]}"


class TestSales(IntegrationTestCase):
	@classmethod
	def setUpClass(cls):
		super().setUpClass()
		cls.company = setup_fixtures()
		frappe.conf.daystar_mobile_company = cls.company

	@classmethod
	def tearDownClass(cls):
		frappe.conf.pop("daystar_mobile_company", None)
		super().tearDownClass()

	def new_lead(self, **fields):
		with self.set_user(OWNER):
			return sales.create_lead(
				first_name=fields.pop("first_name", unique("Lead")),
				mobile_no=fields.pop("mobile_no", "0820000000"),
				**fields,
			)

	def test_a_new_lead_is_daystars_and_owned_by_whoever_captured_it(self):
		lead = self.new_lead(company_name="Acme Farms", notes="Wants 20 panels")

		doc = frappe.get_doc("Lead", lead["name"])
		self.assertEqual(doc.company, self.company)
		self.assertEqual(doc.lead_owner, OWNER)
		self.assertEqual(lead["notes"], "Wants 20 panels")
		self.assertIsNone(lead["customer"])

	def test_a_lead_needs_a_way_to_reach_them(self):
		with self.set_user(OWNER):
			with self.assertRaisesRegex(frappe.ValidationError, "mobile number or an email"):
				sales.create_lead(first_name="Nobody")

	def test_leads_list_keeps_out_the_legacy_company_but_not_leads_without_one(self):
		ours = self.new_lead()["name"]
		no_company = frappe.get_doc(
			{"doctype": "Lead", "first_name": unique("Webform"), "email_id": "web@example.com"}
		).insert(ignore_permissions=True)
		legacy = frappe.get_doc(
			{"doctype": "Lead", "first_name": unique("Legacy"), "email_id": "old@example.com"}
		)
		legacy.company = LEGACY_COMPANY
		legacy.db_insert()

		with self.set_user("Administrator"):
			names = {row["name"] for row in sales.list_leads(filter="all", limit=50)}
			unassigned = {row["name"] for row in sales.list_leads(filter="unassigned", limit=50)}

		self.assertIn(ours, names)
		self.assertIn(no_company.name, names)
		self.assertNotIn(legacy.name, names)
		self.assertNotIn(ours, unassigned)

	def test_lead_to_opportunity_maps_the_lead_into_daystar(self):
		lead = self.new_lead(email_id="buyer@acme.co.za")
		with self.set_user(OWNER):
			opportunity = sales.lead_to_opportunity(lead["name"], amount=12000)

		self.assertEqual(opportunity["opportunity_from"], "Lead")
		self.assertEqual(opportunity["party_name"], lead["name"])
		self.assertEqual(opportunity["amount"], 12000)
		self.assertEqual(frappe.db.get_value("Opportunity", opportunity["name"], "company"), self.company)
		with self.set_user(OWNER):
			self.assertEqual(sales.get_lead(lead["name"])["opportunities"][0]["name"], opportunity["name"])

	def test_making_a_customer_converts_the_lead_once(self):
		lead = self.new_lead(company_name=unique("Acme"))
		with self.set_user(OWNER):
			first = sales.make_customer(lead=lead["name"])
			second = sales.make_customer(lead=lead["name"])

		self.assertEqual(first["name"], second["name"])
		self.assertEqual(first["customer_name"], lead["company_name"])
		self.assertEqual(frappe.db.get_value("Lead", lead["name"], "status"), "Converted")

	def test_an_opportunitys_customer_comes_from_its_lead(self):
		lead = self.new_lead()
		with self.set_user(OWNER):
			opportunity = sales.lead_to_opportunity(lead["name"])
			self.assertIsNone(opportunity["customer"])
			customer = sales.make_customer(opportunity=opportunity["name"])
			self.assertEqual(sales.get_opportunity(opportunity["name"])["customer"]["name"], customer["name"])

	def test_a_quote_for_an_opportunity_is_linked_to_it(self):
		with self.set_user(OWNER):
			opportunity = sales.create_opportunity(CUSTOMER, amount=500)
			quote = documents.submit(
				"Quotation",
				CUSTOMER,
				[{"item_code": ITEM, "qty": 1}],
				str(uuid.uuid4()),
				opportunity=opportunity["name"],
			)
			detail = sales.get_opportunity(opportunity["name"])

		self.assertEqual(frappe.db.get_value("Quotation", quote["name"], "opportunity"), opportunity["name"])
		self.assertEqual(detail["status"], "Quotation")
		self.assertEqual(detail["quotes"][0]["name"], quote["name"])

	def test_only_a_quotation_takes_an_opportunity(self):
		with self.set_user(OWNER):
			opportunity = sales.create_opportunity(CUSTOMER)
			with self.assertRaisesRegex(frappe.ValidationError, "Only a quotation"):
				documents.preview(
					"Sales Invoice", CUSTOMER, [{"item_code": ITEM, "qty": 1}], opportunity["name"]
				)

	def test_a_quote_becomes_one_submitted_invoice(self):
		with self.set_user(OWNER):
			quote = documents.submit("Quotation", CUSTOMER, [{"item_code": ITEM, "qty": 3}], str(uuid.uuid4()))
			first = sales.quote_to_invoice(quote["name"])
			second = sales.quote_to_invoice(quote["name"])
			linked = sales.quote_invoice(quote["name"])

		self.assertEqual(first["doctype"], "Sales Invoice")
		self.assertEqual(first["name"], second["name"])
		self.assertEqual(linked, {"name": first["name"], "docstatus": 1})
		invoice = frappe.get_doc("Sales Invoice", first["name"])
		self.assertEqual(invoice.customer, CUSTOMER)
		self.assertEqual(invoice.items[0].qty, 3)
		self.assertEqual(invoice.grand_total, quote["grand_total"])

	def test_a_draft_quote_cannot_be_invoiced(self):
		with self.set_user(OWNER):
			doc = documents._build("Quotation", CUSTOMER, [{"item_code": ITEM, "qty": 1}])
			doc.insert()
			with self.assertRaisesRegex(frappe.ValidationError, "Submit the quotation"):
				sales.quote_to_invoice(doc.name)

	def test_a_new_customer_gets_a_primary_contact(self):
		with self.set_user(OWNER):
			customer = sales.create_customer(
				unique("Bright Farms"), "Company", email_id="hello@bright.co.za", mobile_no="0831234567"
			)

		doc = frappe.get_doc("Customer", customer["name"])
		self.assertTrue(doc.customer_primary_contact)
		self.assertEqual(customer["email_id"], "hello@bright.co.za")
