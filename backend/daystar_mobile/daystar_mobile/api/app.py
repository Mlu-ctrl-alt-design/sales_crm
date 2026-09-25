"""App status for the Flutter startup gate."""

import frappe
from frappe.utils import cint

MOBILE_CONFIGURATION = "Mobile Configuration"


@frappe.whitelist(allow_guest=True, methods=["GET"])
def get_app_status() -> dict:
	"""Public subset of Mobile Control's Mobile Configuration.

	Guest-readable because the app must honour maintenance mode and the
	minimum version before anyone signs in. Only these four non-sensitive
	fields are exposed; the exposed-forms table stays behind login.

	Reads the stored single values directly so a missing or uninstalled
	Mobile Control reads as "disabled" instead of erroring.
	"""
	values = frappe.db.get_singles_dict(MOBILE_CONFIGURATION)
	return {
		"enabled": bool(cint(values.get("enabled"))),
		"maintenance_mode": bool(cint(values.get("maintenance_mode"))),
		"maintenance_message": values.get("maintenance_message") or None,
		"minimum_app_version": values.get("minimum_app_version") or None,
	}
