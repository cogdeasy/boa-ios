#!/bin/bash
#
# CI entry point for Northbridge Mobile iOS. Called by Jenkinsfile; runs locally too.
#
#   scripts/ci-build.sh            # build + unit tests, Mock scheme (no backend needed)
#   SCHEME=NorthbridgeMobile scripts/ci-build.sh
#   DESTINATION="platform=iOS Simulator,name=iPhone 15" scripts/ci-build.sh
#
set -eo pipefail

cd "$(dirname "$0")/.."

SCHEME="${SCHEME:-NorthbridgeMobile-Mock}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17}"
DERIVED_DATA="${DERIVED_DATA:-build/DerivedData}"
RESULTS_DIR="${RESULTS_DIR:-build/reports}"

mkdir -p "$RESULTS_DIR"
rm -rf "$RESULTS_DIR/NorthbridgeMobile.xcresult" "$RESULTS_DIR/NBFoundation.xcresult"

echo "==> xcodebuild $(xcodebuild -version | head -1)"
echo "==> scheme=$SCHEME destination=$DESTINATION"

if command -v xcpretty >/dev/null 2>&1; then
  PRETTY="xcpretty"
else
  PRETTY="cat"
fi

echo "==> Resolving Swift packages"
xcodebuild -project NorthbridgeMobile.xcodeproj -scheme "$SCHEME" \
  -derivedDataPath "$DERIVED_DATA" -resolvePackageDependencies | $PRETTY

echo "==> Build and test app"
xcodebuild -project NorthbridgeMobile.xcodeproj -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA" \
  -resultBundlePath "$RESULTS_DIR/NorthbridgeMobile.xcresult" \
  CODE_SIGNING_ALLOWED=NO \
  clean test | $PRETTY

echo "==> Test NBFoundation package"
(cd Packages/NBFoundation && xcodebuild -scheme NBFoundation \
  -destination "$DESTINATION" \
  -derivedDataPath "../../$DERIVED_DATA/NBFoundation" \
  -resultBundlePath "../../$RESULTS_DIR/NBFoundation.xcresult" \
  test | $PRETTY)

echo "==> OK"
