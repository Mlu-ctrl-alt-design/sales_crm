# Design direction

Chosen Sep 25, 2026: **Direction A "Ledger"**, plus the **+ quick-create button from Direction C**.
Board: https://claude.ai/artifact/8HgqmJTUSHmKtKFeinDANu (private to Mlu).

Tokens live in `mobile/lib/theme/daystar_theme.dart`.

## Look

- Calm white surfaces; typography carries the hierarchy (Manrope, bundled in `mobile/assets/fonts`).
- One brand blue `#1F4E79` for actions. Green `#16794A` and red `#B3372F` only for money in and out.
- Marigold `#F2A516` only on the + quick-create button (New quote / New invoice / New customer). It hides on Quick send.
- Radius: fields 10, buttons 12, cards and sheets 16. Buttons 52 high, full width at the bottom of a flow.

## Principles

1. One main number per screen, in SA format: `R 12 400,00` (`formatZar`).
2. Every figure names its period and its change against the previous one.
3. On create and send screens, the total and primary action stay fixed at the bottom.
4. Nothing is written without a tap: preview card, then a receipt with the document number.
5. Locks explain themselves: 🔒 plus one line saying why and who to ask.
6. Never lose input: drafts persist; errors show inline with Retry.
7. Progress shows as named steps, not a bare spinner.

## References (Mobbin, iOS)

- Dashboard: [Mercury](https://mobbin.com/screens/dbfdb1d1-6e67-4140-898f-fa30fb78f0a3), [Jobber business health](https://mobbin.com/screens/5097dfd2-931a-4947-9e84-1e629562b152), [Shopify period picker](https://mobbin.com/screens/606af4fa-0740-4fa3-9665-1a670b7b6e19)
- Assistant: [Gemini plan card](https://mobbin.com/screens/319ea467-c382-4bb6-957f-ac3730f49097), [Structured receipt](https://mobbin.com/screens/b9d89e7d-49f0-47bd-bcb1-2b8fe9007e0a), [Linktree AI steps](https://mobbin.com/screens/7e370793-4b21-4992-8738-e417d3ce22dc)
- Quote / invoice: [Jobber create](https://mobbin.com/flows/df8f88e7-78e4-4995-abd3-7720d8664daf), [Jobber send](https://mobbin.com/flows/5a312970-1e30-45f5-92f1-3dc41eebdf9d), [Walmart qty stepper](https://mobbin.com/screens/417d980e-08e0-495e-8964-918261300ef9)
- Gates and sign-in: [PayPal wait](https://mobbin.com/screens/305815a1-eb96-4544-bde7-c1342b7e15ce), [Sonos forced update](https://mobbin.com/screens/8f736fd9-3f9c-42d6-aa2c-413ceecd3ca4), [Deel sign-in](https://mobbin.com/screens/87f59800-7570-4999-9894-32fbd57960fa)
