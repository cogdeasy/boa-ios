#!/bin/bash
#
# Build the Mock scheme and launch it in a booted (or newly booted) iPhone simulator.
#
#   scripts/run-simulator.sh                 # iPhone 17
#   DEVICE="iPhone 16" scripts/run-simulator.sh
#
set -eo pipefail
cd "$(dirname "$0")/.."

DEVICE="${DEVICE:-iPhone 17}"
SCHEME="${SCHEME:-NorthbridgeMobile-Mock}"
CONFIG="${CONFIG:-Mock}"
DERIVED_DATA="build/DerivedData"

UDID=$(xcrun simctl list devices available | grep -E "^\s+$DEVICE \(" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
if [ -z "$UDID" ]; then
  echo "No simulator named '$DEVICE'. Available:"; xcrun simctl list devices available; exit 1
fi

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
open -a Simulator --args -CurrentDeviceUDID "$UDID" 2>/dev/null || true

xcodebuild -project NorthbridgeMobile.xcodeproj -scheme "$SCHEME" -configuration "$CONFIG" \
  -destination "id=$UDID" -derivedDataPath "$DERIVED_DATA" build CODE_SIGNING_ALLOWED=NO | tail -1

APP="$DERIVED_DATA/Build/Products/$CONFIG-iphonesimulator/NorthbridgeMobile.app"
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$APP/Info.plist")
xcrun simctl install "$UDID" "$APP"
xcrun simctl launch "$UDID" "$BUNDLE_ID"
