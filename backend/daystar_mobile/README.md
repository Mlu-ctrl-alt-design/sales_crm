## Daystar Mobile

Backend for the Daystar Sales mobile app. Installed alongside Mobile Control
and Frappe Assistant Core; it never modifies either. See `../../docs/SPEC.md`.

### Layout

- `api/dashboard.py`, `api/documents.py`, `api/assistant.py` — hero-screen endpoints (later phases)
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
