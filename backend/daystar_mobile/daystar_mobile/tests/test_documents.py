"""Quick quote / invoice: preview, idempotent submit and email send."""

import uuid

import frappe
from frappe.tests import IntegrationTestCase

from daystar_mobile.api import documents
from daystar_mobile.tests.test_price_lock import CUSTOMER, ITEM, LIST_RATE, OWNER, REP, setup_fixtures


def new_key():
	return str(uuid.uuid4())


class TestQuickSend(IntegrationTestCase):
	@classmethod
	def setUpClass(cls):
		super().setUpClass()
		cls.company = setup_fixtures()
		frappe.conf.daystar_mobile_company = cls.company

	@classmethod
	def tearDownClass(cls):
		frappe.conf.pop("daystar_mobile_company", None)
		super().tearDownClass()

	def rows(self, **overrides):
		return [{"item_code": ITEM, "qty": 2, **overrides}]

	def test_preview_prices_from_the_price_list_and_saves_nothing(self):
		with self.set_user(OWNER):
			result = documents.preview("Quotation", CUSTOMER, self.rows())

		self.assertIsNone(result["name"])
		self.assertEqual(result["company"], self.company)
		self.assertEqual(result["items"][0]["rate"], LIST_RATE)
		self.assertEqual(result["items"][0]["amount"], 2 * LIST_RATE)
		self.assertEqual(result["net_total"], 2 * LIST_RATE)
		self.assertAlmostEqual(result["grand_total"], result["net_total"] + result["total_taxes"])
		self.assertTrue(result["can_edit_prices"])
		self.assertFalse(frappe.db.exists("Quotation", {"party_name": CUSTOMER, "docstatus": 0}))

	def test_submit_creates_a_submitted_invoice_in_the_app_company(self):
		with self.set_user(OWNER):
			result = documents.submit("Sales Invoice", CUSTOMER, self.rows(), new_key())

		invoice = frappe.get_doc("Sales Invoice", result["name"])
		self.assertEqual(invoice.docstatus, 1)
		self.assertEqual(invoice.company, self.company)
		self.assertEqual(result["total"], invoice.rounded_total or invoice.grand_total)
		self.assertIn("send", result)

	def test_retrying_a_submit_returns_the_same_document(self):
		key = new_key()
		with self.set_user(OWNER):
			first = documents.submit("Quotation", CUSTOMER, self.rows(), key)
			second = documents.submit("Quotation", CUSTOMER, self.rows(), key)

		self.assertEqual(first["name"], second["name"])
		self.assertEqual(frappe.db.count("Quotation", {documents.IDEMPOTENCY_FIELD: key}), 1)

	def test_owner_can_set_a_rate(self):
		with self.set_user(OWNER):
			result = documents.preview("Quotation", CUSTOMER, self.rows(rate=80))
		self.assertEqual(result["items"][0]["rate"], 80)

	def test_rep_changed_rate_is_rejected_at_preview(self):
		with self.set_user(REP):
			with self.assertRaisesRegex(frappe.PermissionError, "must be"):
				documents.preview("Quotation", CUSTOMER, self.rows(rate=80))

	def test_rep_preview_at_list_price_says_prices_are_locked(self):
		with self.set_user(REP):
			result = documents.preview("Quotation", CUSTOMER, self.rows())
		self.assertFalse(result["can_edit_prices"])

	def test_only_quotes_and_invoices(self):
		with self.set_user(OWNER):
			with self.assertRaises(frappe.ValidationError):
				documents.preview("Purchase Invoice", CUSTOMER, self.rows())

	def test_submit_needs_a_proper_key(self):
		with self.set_user(OWNER):
			with self.assertRaises(frappe.ValidationError):
				documents.submit("Quotation", CUSTOMER, self.rows(), "short")

	def test_bad_rows_are_rejected_with_a_plain_message(self):
		with self.set_user(OWNER):
			with self.assertRaisesRegex(frappe.ValidationError, "at least one item"):
				documents.preview("Quotation", CUSTOMER, [])
			with self.assertRaisesRegex(frappe.ValidationError, "more than zero"):
				documents.preview("Quotation", CUSTOMER, self.rows(qty=0))

	def test_search_finds_the_customer_and_the_items_list_price(self):
		with self.set_user(OWNER):
			customers = documents.search_customers("DM Customer")
			items = documents.search_items(CUSTOMER, "DM Item")

		self.assertIn(CUSTOMER, [c.name for c in customers])
		row = next(i for i in items["items"] if i["item_code"] == ITEM)
		self.assertEqual(row["rate"], LIST_RATE)


class TestSendEmail(IntegrationTestCase):
	@classmethod
	def setUpClass(cls):
		super().setUpClass()
		cls.company = setup_fixtures()
		frappe.conf.daystar_mobile_company = cls.company

	@classmethod
	def tearDownClass(cls):
		frappe.conf.pop("daystar_mobile_company", None)
		super().tearDownClass()

	def submitted_quote(self):
		with self.set_user(OWNER):
			return documents.submit("Quotation", CUSTOMER, [{"item_code": ITEM, "qty": 1}], new_key())

	def test_email_is_logged_on_the_document_with_the_pdf(self):
		quote = self.submitted_quote()
		with self.set_user(OWNER):
			result = documents.send_email("Quotation", quote["name"], ["buyer@example.com"])

		comm = frappe.get_doc("Communication", result["communication"])
		self.assertEqual(comm.reference_doctype, "Quotation")
		self.assertEqual(comm.reference_name, quote["name"])
		self.assertIn("buyer@example.com", comm.recipients)
		queued = frappe.get_all(
			"Email Queue", filters={"communication": comm.name}, fields=["attachments"], limit=1
		)
		self.assertTrue(queued, "email was queued")
		self.assertIn("print_format_attachment", queued[0].attachments)

	def test_the_users_own_account_sends_when_they_have_one(self):
		account = frappe.get_doc(
			{
				"doctype": "Email Account",
				"email_account_name": "_Test DM Owner Mailbox",
				"email_id": OWNER,
				"enable_outgoing": 1,
				"smtp_server": "smtp.example.com",
			}
		)
		account.db_insert()  # skips the SMTP login check that insert() would run
		self.assertEqual(documents.outgoing_account_for(OWNER).name, account.name)
		self.assertNotEqual(getattr(documents.outgoing_account_for(REP), "name", None), account.name)

	def test_a_draft_cannot_be_sent(self):
		with self.set_user(OWNER):
			draft = frappe.get_doc(
				{
					"doctype": "Quotation",
					"quotation_to": "Customer",
					"party_name": CUSTOMER,
					"company": self.company,
					"items": [{"item_code": ITEM, "qty": 1}],
				}
			).insert()
			with self.assertRaisesRegex(frappe.ValidationError, "before sending"):
				documents.send_email("Quotation", draft.name, ["buyer@example.com"])

	def test_recipients_must_be_email_addresses(self):
		quote = self.submitted_quote()
		with self.set_user(OWNER):
			with self.assertRaises(frappe.InvalidEmailAddressError):
				documents.send_email("Quotation", quote["name"], ["not-an-email"])
