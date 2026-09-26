import frappe


def before_tests():
	"""Bootstrap ERPNext's standard test data (_Test Company, price lists...).

	Importing erpnext.tests.utils runs its BootStrapTestData.
	"""
	import erpnext.tests.utils

	frappe.db.commit()
