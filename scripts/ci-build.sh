#!/bin/bash
#
# CI entry point for Bank of America Mobile Banking iOS. Called by Jenkinsfile; runs locally too.
#
#   scripts/ci-build.sh            # build + unit tests, Mock scheme (no backend needed)
#   SCHEME=BofAMobile scripts/ci-build.sh
#   DESTINATION="platform=iOS Simulator,name=iPhone 15" scripts/ci-build.sh
#
set -eo pipefail

cd "$(dirname "$0")/.."

SCHEME="${SCHEME:-BofAMobile-Mock}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17}"
DERIVED_DATA="${DERIVED_DATA:-build/DerivedData}"
RESULTS_DIR="${RESULTS_DIR:-build/reports}"

mkdir -p "$RESULTS_DIR"
rm -rf "$RESULTS_DIR/BofAMobile.xcresult" "$RESULTS_DIR/BoAFoundation.xcresult"

echo "==> xcodebuild $(xcodebuild -version | head -1)"
echo "==> scheme=$SCHEME destination=$DESTINATION"

if command -v xcpretty >/dev/null 2>&1; then
  PRETTY="xcpretty"
else
  PRETTY="cat"
fi

echo "==> Resolving Swift packages"
xcodebuild -project BofAMobile.xcodeproj -scheme "$SCHEME" \
  -derivedDataPath "$DERIVED_DATA" -resolvePackageDependencies | $PRETTY

echo "==> Build and test app"
xcodebuild -project BofAMobile.xcodeproj -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA" \
  -resultBundlePath "$RESULTS_DIR/BofAMobile.xcresult" \
  CODE_SIGNING_ALLOWED=NO \
  clean test | $PRETTY

echo "==> Test BoAFoundation package"
(cd Packages/BoAFoundation && xcodebuild -scheme BoAFoundation \
  -destination "$DESTINATION" \
  -derivedDataPath "../../$DERIVED_DATA/BoAFoundation" \
  -resultBundlePath "../../$RESULTS_DIR/BoAFoundation.xcresult" \
  test | $PRETTY)

echo "==> OK"
