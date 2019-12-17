# Cocoapods binary cache

This plugin helps to reduce the build time of Xcode projects which use Cocoapods by prebuilding pod frameworks and cache them in a remote repository to share across multiple machines.

# Demo project and benchmark

To compare build time, we created a demo project with some popular pods added:

```
AFNetworking
SDWebImage
Alamofire
MBProgressHUD
Masonry
SwiftyJSON
SVProgressHUD
MJRefresh
CocoaLumberjack
Realm
SnapKit
Kingfisher
```

To try it:

```
$ cd PodBinaryCacheExample
$ sh BuildBenchMark.sh
```

And the results:

<img src=images/Buildtime-comparision.png width=800></img>

The result will vary depends on your machine and network condition. This is the spec of the machine we used to test the demo project:

```
MacBook Pro (15-inch, 2018)
Mac OS 10.14.6
Processor 2.6 GHz Intel Core i7
Memory 16 GB 2400 MHz DDR4
```

In our real project with around 15% of swift/ObjC code from vendor pods. After applied this technique and monitored on the CI system, we found that overall, it helped to reduce 10% of build time.

<img src=images/realproj_buildtime_trend.png width=800></img>

# Installation

- Install ruby 2.x version and python 3.x (which are usually available on most developers machine!).
- To install the plugin, our preferred way is using Bundler. If you're not familiar with it, please take a look at [Learn how to set it up here](https://www.mokacoding.com/blog/ruby-for-ios-developers-bundler/).

- Just add a line to your Gemfile:

```
gem 'coccoapods-binary-cache', :path => '<path_to_github_repo>' // Will update later after we publishing to github
```

- Then run:

```
$ bundle install
```

# Usage

- Cache config: At the same directory with your Podfile, add a json file and name it `PodBinaryCacheConfig.json` (the name is fixed) and content similar to this:

```
{
  "prebuilt_cache_repo": "<Link to your git repo which will store built frameworks>", // can be https or ssh
  "cache_path": "~/Library/Caches/CocoaPods/PodBinaryCacheExample-libs/"
}
```

- On top of your Podfile add one line below to enable the plugin, it will hook to pod pre-install, post-install to do the build, cache stuffs:

```
plugin 'cocoapods-binary-cache'
```

- Declare pods which need to be prebuilt by adding a flag `:binary => true`:

```
pod 'Alamofire', :binary => true
```

- Run a pod command for the first time adding this plugin, and every time you add/upgrade a pod:

```
$ pod binary-cache --cmd=prebuild
```

It will build frameworks and push to the cache repo and also install prebuilt frameworks to your project. Then just open the Xcode project and build as normal.

- Other members in your team don't need to build again, they just need to fetch prebuilt frameworks from cache and use the project as normal:

```
$ pod binary-cache --cmd=fetch
$ bundle exec pod install
```

# Automate prebuild frameworks on CI

- You can set up to run prebuild frameworks automatically on your CI. Eg. If your project is using gitlab CI, you just need to create a scheduled job (daily) which call the prebuild command:


```
// In .gitlab-ci.yml file
prebuild_pod:
  script:
    - $ pod binary-cache --cmd=prebuild
  only:
    variables:
      - $IS_PREBUILD_DEVPOD_JOB == "true"
```

# How it works

<img src=images/Pods-cache-flow.png width=800></img>

## 1. Prebuild pod frameworks to binary
 + With an added flag (`:binary => true`) to your pod in the Podfile, in the pod pre-install hook, It filters all pods which need to be built, then creates a separated Pod sandbox and generates a Pod.xcproject.
 + Build selected frameworks in the generated project above using xcodebuild command. The products are frameworks and a Manifest file.
 + Compresses all built frameworks to zips and commit to the Binary cache repo.

## 2. Use cached frameworks
 + It fetches from Binary cache repo and unzip all frameworks.
 + In pod pre-install hook, it reads Manifest.lock and Podfile.lock to compare prebuilt lib's version with the one in Podfile.lock, if they're matched -> add to the cache-hit dictionary, otherwise, add to the cache-miss dictionary. Then the plugin intercepts pod install-source flow and base on generated cache hit/miss dictionaries to decide using cached frameworks or source code.

Because we don't upgrade vendor pods every day, even once in a few months, the cache hit rate will likely be 100% most of the time.

# Notes

- We don't support development pod for now and it will be adding in the future.
- A git repo is used as the cache, but we can change to any FTP server with little modification.

# License

The cocoapods-binary-cache plugin is available as open-source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
It uses [cocoapods-rome](https://github.com/CocoaPods/Rome) and [cocoapods-binary](https://github.com/leavez/cocoapods-binary) internally, which are also under MIT License.