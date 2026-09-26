#!/usr/bin/env bash
# Build a TestFlight .ipa on a Mac with Xcode. See docs/TESTFLIGHT.md.
#
#   ./scripts/build_testflight.sh                      # staging
#   SITE_URL=https://crm.thedaystar.co.za ./scripts/build_testflight.sh   # live
set -euo pipefail
cd "$(dirname "$0")/.."

SITE_URL="${SITE_URL:-https://crm-staging.thedaystar.co.za}"
# Every upload needs a higher build number; a timestamp always increases.
BUILD_NUMBER="${BUILD_NUMBER:-$(date -u +%Y%m%d%H%M)}"

echo "Building Daystar Sales $(grep '^version:' pubspec.yaml | cut -d' ' -f2 | cut -d+ -f1) ($BUILD_NUMBER) for $SITE_URL"

flutter pub get
flutter test
flutter build ipa --release \
  --dart-define=SITE_URL="$SITE_URL" \
  --build-number="$BUILD_NUMBER" \
  --export-options-plist=ios/ExportOptions.plist

echo
echo "Done: $(ls build/ios/ipa/*.ipa)"
echo "Upload it with Apple's Transporter app (drag the .ipa in and press Deliver),"
echo "or open build/ios/archive/Runner.xcarchive in Xcode > Organizer > Distribute App."
