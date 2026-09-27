## Daystar Mobile

Backend for the Daystar Sales mobile app. Installed alongside Mobile Control
and Frappe Assistant Core; it never modifies either. See `../../docs/SPEC.md`.

### Layout

- `api/documents.py` — quick quote / invoice: customer and item search, preview, idempotent submit, email send
- `api/dashboard.py`, `api/assistant.py` — hero-screen endpoints (later phases)
- `scope.py` — the one company the app works in (`Daystar`; `daystar_mobile_company` site config overrides)
- `permissions.py` — role helpers and, later, Sales Team scoping hooks
- `price_lock.py` — server-side Price List lock for the Mobile Sales Rep role

### Local development

Never develop or migrate against production. On a local bench:

```sh
bench get-app /path/to/sales_crm/backend/daystar_mobile   # or symlink into apps/
bench --site test.local install-app daystar_mobile
bench --site test.local set-config allow_tests true
bench --site test.local run-tests --app daystar_mobile
```

#### License

mit
