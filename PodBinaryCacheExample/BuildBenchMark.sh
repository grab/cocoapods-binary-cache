build_project() {
  echo "param: " $1
  rm -rf Pods
  rm -rf DerivedData

  start_fetch_time="$(date -u +%s)"
  if [ $1 = "cache_on" ]; then
    echo "fetch prebuilt binary cache"
    pod binary-cache --cmd=fetch
  fi
  end_fetch_time="$(date -u +%s)"
  fetch_cache_time="$(($end_fetch_time-$start_fetch_time))"
  echo 'fetch_cache_time: ' $fetch_cache_time

  echo "Install pods"
  start_install_time="$(date -u +%s)"
  bundle exec pod install
  end_install_time="$(date -u +%s)"
  pod_install_time="$(($end_install_time-$start_install_time))"
  echo 'pod_install_time:' $pod_install_time

  start_build_time="$(date -u +%s)"
  time xcodebuild -workspace PodBinCacheExample.xcworkspace -scheme PodBinCacheExample -configuration Debug -sdk iphonesimulator ARCHS=x86_64 ONLY_ACTIVE_ARCH=YES >/dev/null 2>&1
  end_build_time="$(date -u +%s)"
  xcodebuild_time="$(($end_build_time-$start_build_time))"
  echo 'xcodebuild_time:' $xcodebuild_time
}

export IS_POD_BINARY_CACHE_ENABLED='false'
start_time="$(date -u +%s)"
build_project "cache_off"
end_time="$(date -u +%s)"
buildtime_no_cache="$(($end_time-$start_time))"

export IS_POD_BINARY_CACHE_ENABLED='true'

start_time="$(date -u +%s)"
build_project "cache_on"
end_time="$(date -u +%s)"
buildtime_with_cache="$(($end_time-$start_time))"

echo '-------------------'
echo "Build time no cache: $buildtime_no_cache \nBuild time with cache: $buildtime_with_cache"