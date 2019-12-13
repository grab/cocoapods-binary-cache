# Cocoapods binary cache

This plugin helps to reduce the build time of Xcode projects which use Cocoapods by prebuilding pod frameworks and cache them in a remote repository.

# Installation

- Install ruby 2.x version and python 3.x (which are usually available on most developers machine!).
- To install the plugin, our preferred way is using Bundler. If you're not familiar with it, please take a look at [Learn how to set it up here](https://www.mokacoding.com/blog/ruby-for-ios-developers-bundler/).

- Just add a line to your Gemfile:

```
gem 'coccoapods-binary-cache', :path => '<will update>'
```

- Then run:

```
$ bundle install
```

Or

```
$ bundle install --path <dir_to_install_your_bundle>
```

# Usage

- Add cache config file: At same level with Podfile, add a json file with name `PodBinaryCacheConfig.json` and content similar to this:

```
{
  "prebuilt_cache_repo": "<Link to your git repo to store built frameworks>",
  "cache_path": "~/Library/Caches/CocoaPods/PodBinaryCacheExample-libs/",
  "prebuild_path": "Pods/_Prebuild/",
  "generated_dir_name": "GeneratedFrameworks/",
  "delta_path": "Pods/_Prebuild_delta/changes.txt",
  "manifest_file": "Manifest.lock"
}
```

- Declare pods which need to be prebuilt by adding a flag `:binary => true`:

```
pod 'Alamofire', :binary => true
```

- Run a pod command for the first time adding this plugin, and every time you add/upgrade a pod, you need to run a command:

```
$ pod binary-cache --cmd=prebuild
```

It will build frameworks and push to a cache repo. Then open the Xcode project and use it as normal.

- On other machines, just need to run:

```
$pod binary-cache --cmd=fetch
```

# How it works

## 1. Prebuild pods frameworks to binary
 + With an added flag to your pod in the Podfile, in the pod pre-install hook, It filters all pods which need to be built, then creates a separated Pod sandbox and generates a Pod.xcproject.
 + Build selected frameworks in the generated project above using xcodebuild command. The products are frameworks and a Manifest file.
 + Compresses all built frameworks to zips and commit to the Binary cache repo.

## 2. Use cached frameworks
 + It fetches from Binary cache repo
 + In pod pre-install hook, it reads Manifest.lock and Podfile.lock to compare prebuilt lib's version with the one in Podfile.lock, if they're matched -> add to the cache-hit dictionary, otherwise, add to the cache-miss dictionary. Then the plugin intercepts pod install-source flow and base on generated cache hit/miss dictionaries to decide using cached frameworks or original source code.

Because we don't upgrade vendor pods every day, even once in a few months, the cache hit rate will likely be 100 % most of the time.

# Demo project and benchmark

We created a demo project with some popular pods added to compare build time. To try it:

```
sh BuildBenchMark.sh
```

The result will vary depends on your machine and network condition.

Total build time + fetch cache:

```
Build time no cache: [73.0 sec]
Build time with cache: [35.0 sec]
```

Build time only:

```
Build time no cache: [54.722 sec]
Build time with cache: [14.213 sec]
```

In our real project with around 15% of swift/ObjC code from vendor pods. After applied this technique and monitored on the CI system, we found that overall, it helped to reduce 10% of build time.

<img src=images/realproj_buildtime_trend.png width=800></img>

# Notes

- We don't support local pod for now and it will be adding in the future.
- A git repo is used as the cache, but we can change to any FTP server with little modification.
- You can set up to run prebuild periodically on your CI, but it's not in the scope of this library.

# License

The cocoapods-binary-cache plugin is available as open-source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
It uses cocoapods-rome and cocoapods-binary internally, which are also under MIT License.