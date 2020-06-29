# How cocoapods-binary-cache works

## Terminology
- Cache-hit: a pod framework is prebuilt and has same version with the one in Pod lock file.
- Cache-miss: a pod framework is not prebuilt or has different version with the on in Pod lock file.

<img src=resources/pods_cache_flow.png width=800></img>

## 1. Prebuild pod frameworks to binary and push to cache
 + With an added flag (`:binary => true`) to your pod in the Podfile, in the pod pre-install hook, It filters all pods which need to be built, then creates a separated Pod sandbox and generates a Pod.xcproject. We are using [cocoapods-binary](https://github.com/leavez/cocoapods-binary) for this process.
 + Then it builds frameworks in the generated project above using [cocoapods-rome](https://github.com/CocoaPods/Rome). The products are frameworks and a Manifest file.
 + Compresses all built frameworks to zips and commit to the cache repo.

## 2. Fetch and use cached frameworks
 + It fetches built frameworks from cache repo and unzip them.
 + In pod pre-install hook, it reads Manifest.lock and Podfile.lock to compare prebuilt lib's version with the one in Podfile.lock, if they're matched -> add to the cache-hit dictionary, otherwise, add to the cache-miss dictionary. Then the plugin intercepts pod install-source flow and base on generated cache hit/miss dictionaries to decide using cached frameworks or source code.

Because we don't upgrade vendor pods every day, even once in a few months, the cache hit rate will likely be 100% most of the time.