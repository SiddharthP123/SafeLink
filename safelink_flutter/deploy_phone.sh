#!/usr/bin/env zsh
# deploy_phone.sh
#
# FAST (debug, hot-reload, ~10 sec):    ./deploy_phone.sh --fast
# RELEASE (full build, ~10 min):        ./deploy_phone.sh
# INSTALL-ONLY (skip rebuild, ~5 sec):  ./deploy_phone.sh --install-only
#
# Note: Xcode 26 beta does not support wireless debugging — USB required for all modes.

set -e

DEVICE_ID="00008110-001868523A50201E"       # Flutter / legacy ECID format
DEVICE_UUID="3E852583-7E16-5A4B-97D5-2FFDCBF4E54D" # Xcode 26 devicectl UUID format
IDENTITY="DA6F9CF7B9A0D8A9DBE8892576793F64D0C61928"
BUNDLE_ID="com.Siddharth.SafeLink"
APP="build/ios/iphoneos/Runner.app"

# ── Fast path (debug build, no signing dance) ──────────────────────────────
if [[ "$1" == "--fast" ]]; then
  echo "==> Fast deploy (debug)..."
  flutter run -d "$DEVICE_ID"
  exit 0
fi

# ── Install-only (skip rebuild if app already built) ───────────────────────
if [[ "$1" == "--install-only" ]]; then
  echo "==> Skipping build, re-signing and installing existing build..."
  for framework in "$APP/Frameworks/"*.framework; do
    echo "    signing $(basename $framework)"
    codesign --force --sign "$IDENTITY" --timestamp=none "$framework"
  done
  codesign -d --entitlements :- "$APP" 2>/dev/null > /tmp/runner_entitlements.plist
  codesign --force --sign "$IDENTITY" --timestamp=none \
    --entitlements /tmp/runner_entitlements.plist "$APP"
  xcrun devicectl device install app --device "$DEVICE_UUID" "$APP"
  xcrun devicectl device process launch --device "$DEVICE_UUID" "$BUNDLE_ID"
  echo "Done!"
  exit 0
fi

# ── Full release build ─────────────────────────────────────────────────────
echo "==> Building (release)..."
flutter build ios --release

echo ""
echo "==> Re-signing all frameworks..."
for framework in "$APP/Frameworks/"*.framework; do
  echo "    signing $(basename $framework)"
  codesign --force --sign "$IDENTITY" --timestamp=none "$framework"
done

echo ""
echo "==> Re-signing app bundle..."
codesign -d --entitlements :- "$APP" 2>/dev/null > /tmp/runner_entitlements.plist
codesign --force --sign "$IDENTITY" --timestamp=none \
  --entitlements /tmp/runner_entitlements.plist \
  "$APP"

echo ""
echo "==> Installing on device..."
xcrun devicectl device install app --device "$DEVICE_UUID" "$APP"

echo ""
echo "==> Launching $BUNDLE_ID..."
xcrun devicectl device process launch --device "$DEVICE_UUID" "$BUNDLE_ID"

echo ""
echo "Done! SafeLink is running on your iPhone."
echo ""
echo "Tip: next time run './deploy_phone.sh --fast' for debug mode (~10 sec)"
echo "     or '--install-only' to reinstall without rebuilding."
