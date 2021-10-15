# CocoaPods binary cache

[![Test](https://img.shields.io/github/workflow/status/grab/cocoapods-binary-cache/test)](https://img.shields.io/github/workflow/status/grab/cocoapods-binary-cache/test)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat&color=blue)](https://github.com/grab/cocoapods-binary-cache/blob/master/LICENSE)
[![Gem](https://img.shields.io/gem/v/cocoapods-binary-cache.svg?style=flat&color=blue)](https://rubygems.org/gems/cocoapods-binary-cache)

A plugin that helps to reduce the build time of Xcode projects which use CocoaPods by prebuilding pod frameworks and cache them in a remote repository to share across multiple machines.

## Installation

Requirements

- Ruby: >= 2.4
- CocoaPods: >= 1.5.0

### Via [Bundler](https://bundler.io/)

Add the gem `cocoapods-binary-cache` to the `Gemfile` of your project.

```rb
gem "cocoapods-binary-cache", :git => "https://github.com/grab/cocoapods-binary-cache.git", :tag => "0.1.14"
```

Then, run `bundle install` to install the added gem.

In case you're not familiar with [`bundler`](https://bundler.io/), take a look at [Learn how to set it up here](https://www.mokacoding.com/blog/ruby-for-ios-developers-bundler/).

### Via [RubyGems](https://rubygems.org/)

```sh
$ gem install cocoapods-binary-cache
```

## How it works

Check out the [documentation on how it works](/docs/how_it_works.md) for more information.

## Usage

### 1. Configure cache repo

First of all, create a git repo that will be used as a storage of your prebuilt frameworks. Make sure this git repo is accessible via `git clone` and `git fetch`. Specify this cache repo in the following section.

### 2. Configure Podfile

**2.1. Load the `cocoapods-binary-cache` plugin.**

Add the following line at the beginning of Podfile:

```rb
plugin "cocoapods-binary-cache"
```

**2.2. Configure `cocoapods-binary-cache`**

```rb
config_cocoapods_binary_cache(
  cache_repo: {
    "default" => {
      "remote" => "git@cache_repo.git",
      "local" => "~/.cocoapods-binary-cache/prebuilt-frameworks"
    }
  },
  prebuild_config: "Debug"
)
```
For details about options to use with the `config_cocoapods_binary_cache` function, check out [our guidelines on how to configure `cocoapods-binary-cache`](/docs/configure_cocoapods_binary_cache.md).

**2.3. Declare pods as prebuilt pods**

To declare a pod as a prebuilt pod (sometimes referred to as *binary pod*), add the option `:binary => true` as follows:
```rb
pod "Alamofire", "5.2.1", :binary => true
```

NOTE:

- Dependencies of a prebuilt pod will be automatically treated as prebuilt pods.\
For example, if `RxCocoa` is declared as a prebuilt pod using the `:binary => true` option, then `RxSwift`, one of its dependencies, is also treated as a prebuilt pod.

### 3. CLI

We provided some command line interfaces (CLI):

- Fetch from cache repo
```sh
$ bundle exec pod binary fetch
```
- Prebuild binary pods
```sh
$ bundle exec pod binary prebuild [--push]
```
- Push the prebuilt pods to the cache repo
```sh
$ bundle exec pod binary push
```

For each command, you can run with option `--help` for more details about how to use each:
```sh
$ bundle exec pod binary fetch --help
```

### 4. A trivial workflow

A trivial workflow when using this plugin is to fetch from cache repo, followed by a pod installation, as follows:

```sh
$ bundle exec pod binary fetch
$ bundle exec pod install
```

For other usages, check out the [best practices docs](/docs/best_practices.md).

## Benchmark

We created a project to benchmark how much of the improvements we gain from this plugin. The demo project is using the following pods:

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

Below is the result we recorded:

<img src=resources/benchmark.png width=700></img>

Hardware specs of the above benchmark:
```
MacBook Pro (15-inch, 2018)
Mac OS 10.14.6
Processor 2.6 GHz Intel Core i7
Memory 16 GB 2400 MHz DDR4
```

You can also try it out on your local:
```sh
$ cd PodBinaryCacheExample
$ sh BuildBenchMark.sh
```

In our real project with around 15% of swift/ObjC code from vendor pods. After applying this technique, we notice a reduction of around 10% in build time.
<img src=resources/realproj_buildtime_trend.png width=700></img>

## Known issues and roadmap

### Exporting IPA with Bitcode
- When exporting an IPA with Bitcode, remember to disable the _rebuild from bitcode_ option. Refer to https://github.com/grab/cocoapods-binary-cache/issues/24.

### Pods with headers only
- By default, pods with empty sources (ie. pods with header files only) will be automatically excluded and they will be later integrated as normal. For now, we rely on the `source_files` patterns declared in podspec to heuristically detect empty-sources pods.
- However, there are cases in which the `source_files` of a pod looks like non-empty sources (ex. `s.source_files = "**/*.{c,h,m,mm,cpp}"`) despite having header files only. For those cases, you need to manually add them to the `excluded_pods` option.

## Best practices

Check out our [Best practices](/docs/best_practices.md) for for information.

## Troubleshooting

Check out our [Troubleshooting guidelines](/docs/troubleshooting_guidelines.md) for more information.

## Contribution

Check out [CONTRIBUTING.md](CONTRIBUTING.md) for more information on hw to contribute to this repo.

## License

The cocoapods-binary-cache plugin is available as open-source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
It uses [cocoapods-rome](https://github.com/CocoaPods/Rome) and [cocoapods-binary](https://github.com/leavez/cocoapods-binary) internally, which are also under MIT License.
