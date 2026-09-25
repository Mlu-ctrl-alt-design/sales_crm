import frappe

MOBILE_SALES_REP = "Mobile Sales Rep"


def is_mobile_sales_rep(user: str | None = None) -> bool:
	"""True if the user holds the Mobile Sales Rep role.

	Administrator is excluded because `frappe.get_roles` grants it every role.
	"""
	user = user or frappe.session.user
	if user == "Administrator":
		return False
	return MOBILE_SALES_REP in frappe.get_roles(user)
