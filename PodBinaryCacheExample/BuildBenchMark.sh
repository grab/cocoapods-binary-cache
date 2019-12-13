build_project() {
  echo "param: " $1
  rm -rf Pods
  rm -rf DerivedData
  if [ $1 = "cache_on" ]; then
    echo "fetch prebuilt binary cache"
    pod binary-cache --cmd=fetch
  else
    echo "just instlal"
  fi
  bundle exec pod install
  time xcodebuild -workspace PodBinCacheExample.xcworkspace -scheme PodBinCacheExample -configuration Debug -sdk iphonesimulator ARCHS=x86_64 ONLY_ACTIVE_ARCH=YES 2>&1
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