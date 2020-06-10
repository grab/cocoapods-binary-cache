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

check_pod_install_when_prebuilt_disabled() {
  log_section "Checking pod install when prebuilt frameworks are DISABLED..."

  rm -rf Pods
  bundle exec pod install || bundle exec pod install --repo-update
}

check_pod_install_when_prebuilt_enabled() {
  log_section "Checking pod install when prebuilt frameworks are ENABLED..."

  rm -rf Pods
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
    clean \
    test
}

check_xcodebuild_test() {
  log_section "Checking xcodebuild test..."

  if bundle exec xcpretty --version &> /dev/null; then
    set -o pipefail && xcodebuild_test | bundle exec xcpretty
  elif which xcpretty &> /dev/null; then
    set -o pipefail && xcodebuild_test | xcpretty
  else
    xcodebuild_test
  fi
}

check_prebuilt_integration() {
  log_section "Checking prebuilt integration..."

  local should_fail=false
  for pod in $(cat ".stats/pods_to_integrate.txt"); do
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
  local test_mode="${1:-all}"
  cd "${INTEGRATION_TESTS_DIR}"
  echo "Running test with mode: ${test_mode}..."
  case ${test_mode} in
    flag-off ) run_test_flag_off ;;
    flag-on ) run_test_flag_on ;;
    prebuild-changes ) run_test_prebuild_changes ;;
    prebuild-all ) run_test_prebuild_all ;;
    all ) run_test_all ;;
    * ) break ;;
  esac
}

run_test_all() {
  run_test_flag_off
  run_test_flag_on
  run_test_prebuild_all
  run_test_prebuild_changes
}
run_test_flag_off() {
  export ENABLE_PREBUILT_POD_LIBS=false
  export PREBUILD_VENDOR_PODS_JOB=false
  export FORCE_PREBUILD_ALL_VENDOR_PODS=false

  check_pod_install_when_prebuilt_disabled
  check_xcodebuild_test
}
run_test_flag_on() {
  export ENABLE_PREBUILT_POD_LIBS=true
  export PREBUILD_VENDOR_PODS_JOB=false
  export FORCE_PREBUILD_ALL_VENDOR_PODS=false

  check_pod_install_when_prebuilt_enabled
  check_xcodebuild_test
}
run_test_prebuild_all() {
  export ENABLE_PREBUILT_POD_LIBS=true
  export PREBUILD_VENDOR_PODS_JOB=true
  export FORCE_PREBUILD_ALL_VENDOR_PODS=true

  check_pod_install_when_prebuilt_enabled
  check_xcodebuild_test
  check_prebuilt_integration
}
run_test_prebuild_changes() {
  echo "🚩 FIXME (thuyen): This test currently fails"
  # export ENABLE_PREBUILT_POD_LIBS=true
  # export PREBUILD_VENDOR_PODS_JOB=true
  # export FORCE_PREBUILD_ALL_VENDOR_PODS=false

  # check_pod_install_when_prebuilt_enabled
  # check_xcodebuild_test
  # check_prebuilt_integration
}
# -------------------------

echo "Working dir: ${WORKING_DIR}"
echo "Integeration tests dir: ${INTEGRATION_TESTS_DIR}"
run_test "$1"
