#!/bin/bash
set -e
# set -o pipefail

export WORKING_DIR=$(PWD)
export INTEGRATION_TESTS_DIR="${WORKING_DIR}/integration_tests"
export TEST_DEVICE=${INTEGRATION_TEST_DEVICE_NAME:-iPhone 8}
export DERIVED_DATA_PATH=${DERIVED_DATA_PATH:-DerivedData}

log_section() {
  echo "-------------------------------------------"
  echo "$1"
  echo "-------------------------------------------"
}

check_pod_install_when_prebuilt_disabled() {
  log_section "Checking pod install when prebuilt frameworks are DISABLED..."

  export PREBUILD_VENDOR_PODS_JOB=false
  export ENABLE_PREBUILT_POD_LIBS=false
  export FORCE_PREBUILD_ALL_VENDOR_PODS=false

  rm -rf Pods
  bundle exec pod install || bundle exec pod install --repo-update
}

check_pod_install_when_prebuilt_enabled() {
  log_section "Checking pod install when prebuilt frameworks are ENABLED..."

  export PREBUILD_VENDOR_PODS_JOB=true
  export ENABLE_PREBUILT_POD_LIBS=true
  export FORCE_PREBUILD_ALL_VENDOR_PODS=true

  rm -rf Pods
  bundle exec pod install
  bundle exec pod binary-cache --cmd=fetch
  bundle exec pod install || bundle exec pod install --repo-update
}

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
  log_section "Checking xcodebuild test..."

  if bundle exec xcpretty --version &> /dev/null; then
    xcodebuild_test | bundle exec xcpretty
  elif which xcpretty &> /dev/null; then
    xcodebuild_test | xcpretty
  else
    xcodebuild_test
  fi
}

check_prebuilt_integration() {
  log_section "Checking prebuilt integration..."

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

  check_pod_install_when_prebuilt_disabled
  check_pod_install_when_prebuilt_enabled

  check_prebuilt_integration
  check_xcodebuild_test
}

# -------------------------
echo "Working dir: ${WORKING_DIR}"
echo "Integeration tests dir: ${INTEGRATION_TESTS_DIR}"
run_test
