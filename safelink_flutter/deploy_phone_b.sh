#!/usr/bin/env zsh
# deploy_phone_b.sh — deploys SafeLink to Phone B (second test device)
#
# RELEASE (full build, ~10 min):        ./deploy_phone_b.sh
# INSTALL-ONLY (skip rebuild, ~5 sec):  ./deploy_phone_b.sh --install-only
#
# ── FILL THESE IN after connecting Phone B ────────────────────────────────
# Run: flutter devices          → copy the UDID for DEVICE_ID_B
# Run: xcrun devicectl list devices → copy the Identifier for DEVICE_UUID_B

DEVICE_ID_B="00008110-000651E836D1801E"
DEVICE_UUID_B="DEED92D4-DE98-5975-9457-B6ADFDC626AC"
# ─────────────────────────────────────────────────────────────────────────

IDENTITY="DA6F9CF7B9A0D8A9DBE8892576793F64D0C61928"
BUNDLE_ID="com.Siddharth.SafeLink"
APP="build/ios/iphoneos/Runner.app"

if [[ "$DEVICE_ID_B" == "FILL_IN_ECID" ]]; then
  echo "ERROR: Fill in DEVICE_ID_B and DEVICE_UUID_B in this script first."
  echo "  1. Connect Phone B via USB"
  echo "  2. Run: flutter devices"
  echo "  3. Run: xcrun devicectl list devices"
  exit 1
fi

if [[ "$1" == "--install-only" ]]; then
  echo "==> Skipping build, re-signing and installing on Phone B..."
  for framework in "$APP/Frameworks/"*.framework; do
    codesign --force --sign "$IDENTITY" --timestamp=none "$framework"
  done
  codesign -d --entitlements :- "$APP" 2>/dev/null > /tmp/runner_entitlements.plist
  codesign --force --sign "$IDENTITY" --timestamp=none \
    --entitlements /tmp/runner_entitlements.plist "$APP"
  xcrun devicectl device install app --device "$DEVICE_UUID_B" "$APP"
  xcrun devicectl device process launch --device "$DEVICE_UUID_B" "$BUNDLE_ID"
  echo "Done! SafeLink is running on Phone B."
  exit 0
fi

echo "==> Building (release)..."
flutter build ios --release

echo ""
echo "==> Re-signing all frameworks..."
for framework in "$APP/Frameworks/"*.framework; do
  codesign --force --sign "$IDENTITY" --timestamp=none "$framework"
done

echo ""
echo "==> Re-signing app bundle..."
codesign -d --entitlements :- "$APP" 2>/dev/null > /tmp/runner_entitlements.plist
codesign --force --sign "$IDENTITY" --timestamp=none \
  --entitlements /tmp/runner_entitlements.plist \
  "$APP"

echo ""
echo "==> Installing on Phone B..."
xcrun devicectl device install app --device "$DEVICE_UUID_B" "$APP"

echo ""
echo "==> Launching..."
xcrun devicectl device process launch --device "$DEVICE_UUID_B" "$BUNDLE_ID"

echo ""
echo "Done! SafeLink is running on Phone B."
echo "Tip: next time run './deploy_phone_b.sh --install-only' (~5 sec)"
