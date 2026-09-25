# Daystar Sales (Flutter)

Mobile client for the Daystar ERPNext site. See `../docs/SPEC.md`.

```sh
flutter pub get
flutter run                                        # debug build: https://crm-staging.thedaystar.co.za
flutter build apk --release                        # release build: https://crm.thedaystar.co.za (live)
flutter run --dart-define=SITE_URL=http://<bench>  # any other site, e.g. a local bench
flutter test
```

On launch the app calls Mobile Control's `mobile_auth.app_status` and blocks
itself when Mobile Configuration is disabled, in maintenance mode, or requires
a newer version than the installed build.

With Face ID / fingerprint unlock on, the app locks after 5 minutes in the
background and unlocks on top of where the user left off.

Sign-in is stubbed (`PendingMobileControlAuthRepository`) until Mobile
Control's token endpoints have been inspected.
