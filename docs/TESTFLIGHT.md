# Getting Daystar Sales onto TestFlight

Builds point at **staging** (`crm-staging.thedaystar.co.za`) unless you choose otherwise. The live site has Mobile Configuration switched off, so a build pointed there opens to "The app is switched off".

## 1. Apple side (once)

1. **Apple Developer Program** membership for the account that will own the app.
2. **App Store Connect → Apps → + New App**
   - Platform: iOS
   - Name: Daystar Sales
   - Bundle ID: `za.co.thedaystar.daystarSales`. If it isn't in the list, register it under Certificates, IDs & Profiles → Identifiers first.
   - SKU: anything, e.g. `daystar-sales`
3. **TestFlight → Internal Testing → +** to create a group and add yourself. Internal testers don't need Apple's beta review, so a build is installable minutes after processing.

## 2. Staging side (once)

- Give each tester's Frappe user the **Mobile User** role. Mobile Control refuses app sign-in without it.
- Mobile Configuration is already enabled on staging. Leave `minimum_app_version` blank for now.

## 3a. Build on a Mac

Needs Xcode (current release) and Flutter 3.35.

```sh
cd mobile
open ios/Runner.xcworkspace        # once: Runner target → Signing & Capabilities → Team
./scripts/build_testflight.sh      # tests, then builds build/ios/ipa/*.ipa for staging
```

Upload the `.ipa` with Apple's **Transporter** app: drag it in and press Deliver. Alternatively, open the archive in Xcode → Organizer → Distribute App → TestFlight.

## 3b. Or build on GitHub (no Mac needed)

Create an App Store Connect API key under **Users and Access → Integrations → App Store Connect API → +**. Give it the Admin role so Xcode can create signing certificates in the cloud. Download the `.p8` file; Apple only lets you download it once.

Add these repository secrets under **Settings → Secrets and variables → Actions**:

| Secret | Value |
| --- | --- |
| `APPLE_TEAM_ID` | 10-character Team ID (Membership details) |
| `ASC_KEY_ID` | Key ID shown next to the API key |
| `ASC_ISSUER_ID` | Issuer ID at the top of the API keys page |
| `ASC_KEY_P8` | Full contents of the `.p8` file, including the BEGIN/END lines |

Then go to **Actions → iOS TestFlight → Run workflow** and keep the staging URL. The run tests the app, signs it, and uploads it. The build appears in TestFlight after Apple finishes processing, usually 5–15 minutes.

## What testers will see

- Startup check, then sign-in with their Frappe email and password.
- An offer to turn on Face ID after the first sign-in, and a lock after 5 minutes away.
- Dashboard, Assistant and Quick send tabs, which are placeholders in Phase 1, plus the + button.

## Notes

- The build number is a timestamp (Mac) or the GitHub run number, so each upload is higher than the last.
- The app is iPhone-only, so no iPad screenshots are needed later.
- `ITSAppUsesNonExemptEncryption` is `false` because the app only uses standard HTTPS. That skips the export-compliance question on each build.
