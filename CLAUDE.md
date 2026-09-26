# Daystar Sales Mobile App — Claude Code brief

Read `docs/SPEC.md` first. It is the source of truth; this file tells you how to work on it.

## What you're building

Two things, in one repo:

- `backend/daystar_mobile/` — a custom Frappe app installed on the Daystar ERPNext site alongside the existing **Mobile Control** and **Frappe Assistant Core (FAC)** apps.
- `mobile/` — a Flutter app that reads its form configuration from Mobile Control and calls `daystar_mobile` whitelisted endpoints for the three hero screens.

The Expo / React Native prototype at the repo root (`app/`, `components/`, `api/`, `src/`) predates the spec and is not part of v1.

## Hard rules

- Never modify the Mobile Control or FAC apps. Extend through `daystar_mobile` hooks and endpoints only.
- Never develop or run migrations against the production site. Use a local bench or staging site.
- Company scope is `Daystar` (ZAR) only. Exclude `The Daystar` (USD) from every query.
- No Claude API key on the device. It lives in site config (`daystar_mobile_anthropic_key`).
- The assistant never executes a write tool directly. Writes become an `Assistant Pending Action` and run only via `assistant.confirm`.
- Rep price lock is enforced server-side (permlevel + `validate` hook), never only in Flutter.
- Every whitelisted endpoint checks permissions as `frappe.session.user`; no `ignore_permissions=True` on user-facing paths.

## Phase 1 scope

1. Scaffold `daystar_mobile` (`bench new-app`), with modules `api/` (`dashboard.py`, `documents.py`, `assistant.py`) and a `permissions.py`.
2. Create the role **Mobile Sales Rep** (fixture), no Desk access.
3. Price lock: raise permlevel on `rate` and `discount_percentage` for Quotation Item and Sales Invoice Item for that role (Property Setter fixtures), plus `validate` hooks on Quotation and Sales Invoice that reject rates differing from the Price List rate for users with that role.
4. Doctypes: `Assistant Pending Action` (user, tool name, arguments JSON, status, expires_at, result) and `Assistant Log` (user, message, tool calls, outcome).
5. Flutter skeleton: token auth against Mobile Refresh Token, Mobile Configuration check (enabled, minimum version, maintenance mode), and an empty shell with the three hero tabs.
6. Tests: a rep cannot submit a Quotation with a modified rate via direct API; maintenance mode blocks the app.

Before writing the Flutter auth, inspect the Mobile Control app's endpoints on the bench to learn its token contract. Don't guess it.

## Ask before deciding

- Claude model and monthly spend cap for the assistant.
- Which outgoing email account sends documents.
- How Mobile Control renders child tables on generic forms (inspect and report back).

## Working style

- Small commits, one concern each. Summarise what changed and what's next at the end of each session.
- When a requirement in the spec conflicts with what you find in the code, report the conflict; don't silently pick one.
