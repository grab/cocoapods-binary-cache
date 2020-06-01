#!/bin/bash
set -e
set -o pipefail

WORKING_DIR=$(PWD)
INTEGRATION_TESTS_DIR="${WORKING_DIR}/integration_tests"
TEST_DEVICE=${INTEGRATION_TEST_DEVICE_NAME:-iPhone 8}
DERIVED_DATA_PATH=${DERIVED_DATA_PATH:-DerivedData}

xcodebuild_test() {
  xcodebuild \
  -workspace PrebuiltPodIntegration.xcworkspace \
  -scheme PrebuiltPodIntegration \
  -configuration Debug \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=${TEST_DEVICE}" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  test
}

check_xcodebuild_test() {
  if bundle exec xcpretty --version &> /dev/null; then
    xcodebuild_test | bundle exec xcpretty
  elif which xcpretty &> /dev/null; then
    xcodebuild_test | xcpretty
  else
    xcodebuild_test
  fi
}

check_prebuilt_integration() {
  local should_fail=false
  for pod in $(cat ".stats/prebuilt_binary_pods.txt"); do
    local framework_dir="Pods/${pod}/${pod}.framework"
    if [[ ! -f "${framework_dir}/${pod}" ]]; then
      should_fail=true
      echo "🚩 Prebuilt framework ${pod} was not integrated. Expect to have: ${framework_dir}"
    fi
  done
  if [[ ${should_fail} == "true" ]]; then
    exit 1
  fi
}

run_test() {
  cd "${INTEGRATION_TESTS_DIR}"
  rm -rf Pods
  bundle exec pod binary-cache --cmd=fetch
  bundle exec pod install || bundle exec pod install --repo-update

  check_prebuilt_integration
  check_xcodebuild_test
}

handle_error() {
  cd "${WORKING_DIR}"
  rm -rf "${DERIVED_DATA_PATH}"
  exit 1
}

# -------------------------
export PREBUILD_VENDOR_PODS_JOB=true
export ENABLE_PREBUILT_POD_LIBS=true
export FORCE_PREBUILD_ALL_VENDOR_PODS=true

echo "Working dir: ${WORKING_DIR}"
echo "Integeration tests dir: ${INTEGRATION_TESTS_DIR}"
run_test || handle_error
