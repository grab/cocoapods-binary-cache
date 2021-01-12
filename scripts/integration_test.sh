#!/bin/bash
set -e

export WORKING_DIR=$(PWD)
export INTEGRATION_TESTS_DIR="${WORKING_DIR}/integration_tests"
export TEST_DEVICE=${INTEGRATION_TEST_DEVICE_NAME:-iPhone 8}
export DERIVED_DATA_PATH=${DERIVED_DATA_PATH:-DerivedData}

log_section() {
  echo "-------------------------------------------"
  echo "$1"
  echo "-------------------------------------------"
}

pod_install() {
  bundle exec pod install --ansi || bundle exec pod install --ansi --repo-update
}

pod_bin_fetch() {
  bundle exec pod binary fetch --ansi
}

pod_bin_prebuild() {
  bundle exec pod binary prebuild --ansi $1
}

xcodebuild_test() {
  log_section "Running xcodebuild test..."

  set -o pipefail && env NSUnbufferedIO=YES xcodebuild \
    -workspace PrebuiltPodIntegration.xcworkspace \
    -scheme PrebuiltPodIntegration \
    -configuration Debug \
    -sdk "iphonesimulator" \
    -destination "platform=iOS Simulator,name=${TEST_DEVICE}" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    clean \
    test | bundle exec xcpretty --color
}

# -------------------------

echo "Working dir: ${WORKING_DIR}"
echo "Integeration tests dir: ${INTEGRATION_TESTS_DIR}"

TEST_MODE="${1:-prebuild-all}"
cd "${INTEGRATION_TESTS_DIR}"
echo "Running test with mode: ${TEST_MODE}..."

rm -rf Pods _Prebuild DerivedData
case ${TEST_MODE} in
  non-prebuild )
    pod_bin_fetch
    pod_install
    xcodebuild_test
    ;;
  prebuild-changes )
    pod_bin_prebuild
    xcodebuild_test
    ;;
  prebuild-all )
    pod_bin_prebuild --all
    xcodebuild_test
    ;;
  * ) break ;;
esac
