app_name = "daystar_mobile"
app_title = "Daystar Mobile"
app_publisher = "Daystar"
app_description = "Backend for the Daystar Sales mobile app"
app_email = "mlumanda@gmail.com"
app_license = "mit"

fixtures = [
	{"dt": "Role", "filters": [["name", "=", "Mobile Sales Rep"]]},
	{
		"dt": "Property Setter",
		"filters": [
			[
				"name",
				"in",
				[
					"Quotation Item-rate-permlevel",
					"Quotation Item-discount_percentage-permlevel",
					"Sales Invoice Item-rate-permlevel",
					"Sales Invoice Item-discount_percentage-permlevel",
				],
			]
		],
	},
]

after_install = "daystar_mobile.price_lock.setup_price_lock_permissions"
after_migrate = "daystar_mobile.price_lock.setup_price_lock_permissions"

doc_events = {
	"Quotation": {"validate": "daystar_mobile.price_lock.validate_price_list_rates"},
	"Sales Invoice": {"validate": "daystar_mobile.price_lock.validate_price_list_rates"},
}

# Apps
# ------------------

required_apps = ["erpnext"]

# Each item in the list will be shown as an app in the apps page
# add_to_apps_screen = [
# 	{
# 		"name": "daystar_mobile",
# 		"logo": "/assets/daystar_mobile/logo.png",
# 		"title": "Daystar Mobile",
# 		"route": "/daystar_mobile",
# 		"has_permission": "daystar_mobile.api.permission.has_app_permission"
# 	}
# ]

# Includes in <head>
# ------------------

# include js, css files in header of desk.html
# app_include_css = "/assets/daystar_mobile/css/daystar_mobile.css"
# app_include_js = "/assets/daystar_mobile/js/daystar_mobile.js"

# include js, css files in header of web template
# web_include_css = "/assets/daystar_mobile/css/daystar_mobile.css"
# web_include_js = "/assets/daystar_mobile/js/daystar_mobile.js"

# include custom scss in every website theme (without file extension ".scss")
# website_theme_scss = "daystar_mobile/public/scss/website"

# include js, css files in header of web form
# webform_include_js = {"doctype": "public/js/doctype.js"}
# webform_include_css = {"doctype": "public/css/doctype.css"}

# include js in page
# page_js = {"page" : "public/js/file.js"}

# include js in doctype views
# doctype_js = {"doctype" : "public/js/doctype.js"}
# doctype_list_js = {"doctype" : "public/js/doctype_list.js"}
# doctype_tree_js = {"doctype" : "public/js/doctype_tree.js"}
# doctype_calendar_js = {"doctype" : "public/js/doctype_calendar.js"}

# Svg Icons
# ------------------
# include app icons in desk
# app_include_icons = "daystar_mobile/public/icons.svg"

# Home Pages
# ----------

# application home page (will override Website Settings)
# home_page = "login"

# website user home page (by Role)
# role_home_page = {
# 	"Role": "home_page"
# }

# Generators
# ----------

# automatically create page for each record of this doctype
# website_generators = ["Web Page"]

# automatically load and sync documents of this doctype from downstream apps
# importable_doctypes = [doctype_1]

# Jinja
# ----------

# add methods and filters to jinja environment
# jinja = {
# 	"methods": "daystar_mobile.utils.jinja_methods",
# 	"filters": "daystar_mobile.utils.jinja_filters"
# }

# Installation
# ------------

# before_install = "daystar_mobile.install.before_install"
# after_install = "daystar_mobile.install.after_install"

# Uninstallation
# ------------

# before_uninstall = "daystar_mobile.uninstall.before_uninstall"
# after_uninstall = "daystar_mobile.uninstall.after_uninstall"

# Integration Setup
# ------------------
# To set up dependencies/integrations with other apps
# Name of the app being installed is passed as an argument

# before_app_install = "daystar_mobile.utils.before_app_install"
# after_app_install = "daystar_mobile.utils.after_app_install"

# Integration Cleanup
# -------------------
# To clean up dependencies/integrations with other apps
# Name of the app being uninstalled is passed as an argument

# before_app_uninstall = "daystar_mobile.utils.before_app_uninstall"
# after_app_uninstall = "daystar_mobile.utils.after_app_uninstall"

# Build
# ------------------
# To hook into the build process

# after_build = "daystar_mobile.build.after_build"

# Desk Notifications
# ------------------
# See frappe.core.notifications.get_notification_config

# notification_config = "daystar_mobile.notifications.get_notification_config"

# Awesome Bar
# -----------
# Extra search results: list of dicts with label, description, route, index.
# route: ["List", "ToDo"], "/desk/docs/some/page", or "https://example.com"
# awesomebar_search = ["daystar_mobile.search.awesomebar_results"]

# Permissions
# -----------
# Permissions evaluated in scripted ways

# permission_query_conditions = {
# 	"Event": "frappe.desk.doctype.event.event.get_permission_query_conditions",
# }
#
# has_permission = {
# 	"Event": "frappe.desk.doctype.event.event.has_permission",
# }

# Document Events
# ---------------
# Hook on document methods and events

# doc_events = {
# 	"*": {
# 		"on_update": "method",
# 		"on_cancel": "method",
# 		"on_trash": "method"
# 	}
# }

# Scheduled Tasks
# ---------------

# scheduler_events = {
# 	"all": [
# 		"daystar_mobile.tasks.all"
# 	],
# 	"daily": [
# 		"daystar_mobile.tasks.daily"
# 	],
# 	"hourly": [
# 		"daystar_mobile.tasks.hourly"
# 	],
# 	"weekly": [
# 		"daystar_mobile.tasks.weekly"
# 	],
# 	"monthly": [
# 		"daystar_mobile.tasks.monthly"
# 	],
# }

# Testing
# -------

before_tests = "daystar_mobile.tests.before_tests"

# Extend DocType Class
# ------------------------------
#
# Specify custom mixins to extend the standard doctype controller.
# extend_doctype_class = {
# 	"Task": "daystar_mobile.custom.task.CustomTaskMixin"
# }

# Overriding Methods
# ------------------------------
#
# override_whitelisted_methods = {
# 	"frappe.desk.doctype.event.event.get_events": "daystar_mobile.event.get_events"
# }
#
# each overriding function accepts a `data` argument;
# generated from the base implementation of the doctype dashboard,
# along with any modifications made in other Frappe apps
# override_doctype_dashboards = {
# 	"Task": "daystar_mobile.task.get_dashboard_data"
# }

# exempt linked doctypes from being automatically cancelled
#
# auto_cancel_exempted_doctypes = ["Auto Repeat"]

# Ignore links to specified DocTypes when deleting documents
# -----------------------------------------------------------

# ignore_links_on_delete = ["Communication", "ToDo"]

# Request Events
# ----------------
# before_request = ["daystar_mobile.utils.before_request"]
# after_request = ["daystar_mobile.utils.after_request"]

# Job Events
# ----------
# before_job = ["daystar_mobile.utils.before_job"]
# after_job = ["daystar_mobile.utils.after_job"]

# User Data Protection
# --------------------

# user_data_fields = [
# 	{
# 		"doctype": "{doctype_1}",
# 		"filter_by": "{filter_by}",
# 		"redact_fields": ["{field_1}", "{field_2}"],
# 		"partial": 1,
# 	},
# 	{
# 		"doctype": "{doctype_2}",
# 		"filter_by": "{filter_by}",
# 		"partial": 1,
# 	},
# 	{
# 		"doctype": "{doctype_3}",
# 		"strict": False,
# 	},
# 	{
# 		"doctype": "{doctype_4}"
# 	}
# ]

# Authentication and authorization
# --------------------------------

# auth_hooks = [
# 	"daystar_mobile.auth.validate"
# ]

# Automatically update python controller files with type annotations for this app.
# export_python_type_annotations = True

# default_log_clearing_doctypes = {
# 	"Logging DocType Name": 30  # days to retain logs
# }

# Translation
# ------------
# List of apps whose translatable strings should be excluded from this app's translations.
# ignore_translatable_strings_from = []
