import frappe
from frappe.tests.test_api import FrappeAPITestCase

from daystar_mobile.api.app import MOBILE_CONFIGURATION

ENDPOINT = "daystar_mobile.api.app.get_app_status"


def set_config(**values):
	"""Write Mobile Configuration singles directly; Mobile Control need not be installed."""
	frappe.db.delete("Singles", {"doctype": MOBILE_CONFIGURATION})
	for field, value in values.items():
		frappe.db.sql(
			"insert into `tabSingles` (doctype, field, value) values (%s, %s, %s)",
			(MOBILE_CONFIGURATION, field, value),
		)
	frappe.db.commit()


class TestAppStatus(FrappeAPITestCase):
	def tearDown(self):
		frappe.db.delete("Singles", {"doctype": MOBILE_CONFIGURATION})
		frappe.db.commit()
		super().tearDown()

	def status(self):
		# No auth header: the gate runs before sign-in.
		response = self.get(self.method(ENDPOINT))
		self.assertEqual(response.status_code, 200, response.json)
		return response.json["message"]

	def test_maintenance_mode_blocks_the_app(self):
		set_config(enabled=1, maintenance_mode=1, maintenance_message="Back at 14:00")
		self.assertEqual(
			self.status(),
			{
				"enabled": True,
				"maintenance_mode": True,
				"maintenance_message": "Back at 14:00",
				"minimum_app_version": None,
			},
		)

	def test_open_config(self):
		set_config(enabled=1, maintenance_mode=0, minimum_app_version="1.2.0")
		status = self.status()
		self.assertTrue(status["enabled"])
		self.assertFalse(status["maintenance_mode"])
		self.assertEqual(status["minimum_app_version"], "1.2.0")

	def test_missing_configuration_reads_as_disabled(self):
		self.assertFalse(self.status()["enabled"])

	def test_exposes_only_the_gate_fields(self):
		set_config(enabled=1, package_name="za.co.thedaystar.daystar_sales")
		self.assertEqual(
			set(self.status()), {"enabled", "maintenance_mode", "maintenance_message", "minimum_app_version"}
		)
