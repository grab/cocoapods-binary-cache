# Configure cocoapods-binary-cache

This document guides you through how to config `cocoapods-binary-cache` via the `config_cocoapods_binary_cache` method in Podfile.

Following are the options available in `config_cocoapods_binary_cache`. Options marked with (*) are mandatory for the plugin.

### `cache_repo` (*)

Configure cache repo
```rb
config_cocoapods_binary_cache(
  cache_repo: {
    "default" => {
      "remote" => "git@cache_repo.git",
      "local" => "~/.cocoapods-binary-cache/prebuilt-frameworks-debug-config"
    },
    "test" => {
      "remote" => "git@another_cache_repo.git",
      "local" => "~/.cocoapods-binary-cache/prebuilt-frameworks-test-config"
    }
  }
)
```

Note: The cache repo can be specified in the CLI of `fetch`/`prebuild`/`push` command with the `--repo` option (`default` is used if not specified):
```sh
bundle exec pod binary fetch --repo=test
```

### `prebuild_sandbox_path`
- Default: `_Prebuild`.
- The path to the prebuild sandbox.

### `prebuild_config`
- Default: `Debug`.
- The configuration to use (such as `Debug`) when prebuilding pods.

Note: This config can be overriden by the option `--config` in the `prebuild` CLI:
```sh
bundle exec pod binary prebuild --config=Test
```

### `excluded_pods`
- Default: `[]`.
- A list of pods to exclude (ie. treat them as non-prebuilt pods).

Note:
- By default, pods with empty sources (ie. pods with header files only) will be automatically excluded and they will be later integrated as normal. For now, we rely on the `source_files` patterns declared in podspec to heuristically detect empty-sources pods.
- However, there are cases in which the `source_files` of a pod looks like non-empty sources (ex. `s.source_files = "**/*.{c,h,m,mm,cpp}"`) despite having header files only. For those cases, you need to manually add them to the `excluded_pods` option.

### `bitcode_enabled`
- Default: `false`.
- Enable bitcode generation when building frameworks

### `device_build_enabled`
- Default: `false`.
- Enable prebuilt frameworks to be used with devices.

### `xcframework`
- Default: `false`.
- Enable `xcframework` support. This is useful when prebuilding for multi architectures (for simulators & devices).\
NOTE: On ARM-based macs, please set this option to `true` as creating fat binaries with `lipo` no longer works on those machines.

### `disable_dsym`
- Default: `false`.
- Disable dSYM generation when prebuilding frameworks.

### `save_cache_validation_to`
- Default: `nil`.
- The path to save cache validation (missed/hit). Do nothing if not specified.

### `validate_prebuilt_settings`
- Default: `nil`.
- Validate build settings of the prebuilt frameworks. A framework that has incompatible build settings will be treated as a cache miss. If this option is not specified, only versions of the prebuilt pods are used to check for cache hit/miss. Below is a sample build settings validation:
```rb
config_cocoapods_binary_cache(
  validate_prebuilt_settings: lambda { |target|
    settings = {}
    settings["MACH_O_TYPE"] = "mh_dylib" if must_be_dynamic_frameworks.include?(target)
    settings["SWIFT_VERSION"] = swift_version_for(target)
    settings
  }
)
```

### `prebuild_code_gen`
- Default: `nil`.
- This option provide a hook to run code generation for prebuilding frameworks (in a prebuild job). A typical example is when you need to generate code using [R.swift](https://github.com/mac-cain13/R.swift).
  - If the code generation is independent of `Pods.xcodeproj`, it is recommended to move code generation prior to pod installation. In that case, you don't need this option.
  - Otherwise, use this option to trigger code generation. It will be triggered just before prebuilding frameworks.\
  Do take note that if the code generation requires the `Pods.xcodeproj`, the project should correspond to the prebuilt sandbox (for ex. `_Prebuild/`, accessed via `installer.sandbox.root`), not the standard sandbox (`Pods`)
```rb
config_cocoapods_binary_cache(
  prebuild_code_gen: lambda { |installer, targets_to_prebuild|
    `sh scripts/codegen_for_prebuild.sh`
  }
)
```

### `silent_build`
- Default: `false`.
- Suppress build output