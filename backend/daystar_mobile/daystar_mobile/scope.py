"""Which ERPNext company the app works in.

v1 is Daystar (ZAR) only; the legacy "The Daystar" (USD) company is never
touched. A site can point the app elsewhere with the
`daystar_mobile_company` site config key (tests use it for _Test Company).
"""

import frappe

DEFAULT_COMPANY = "Daystar"


def get_company() -> str:
	return frappe.conf.get("daystar_mobile_company") or DEFAULT_COMPANY
