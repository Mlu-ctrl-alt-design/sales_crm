# Daystar Sales (Flutter)

Mobile client for the Daystar ERPNext site. See `../docs/SPEC.md`.

```sh
flutter pub get
flutter run --dart-define=SITE_URL=https://<staging-site>
flutter test
```

On launch the app calls `daystar_mobile.api.app.get_app_status` and blocks
itself when Mobile Configuration is disabled, in maintenance mode, or requires
a newer version than the installed build.

Sign-in is stubbed (`PendingMobileControlAuthRepository`) until Mobile
Control's token endpoints have been inspected.
