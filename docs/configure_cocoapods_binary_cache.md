# Configure cocoapods-binary-cache

This document guides you through how to config `cocoapods-binary-cache` via the `config_cocoapods_binary_cache` method in Podfile.

```rb
config_cocoapods_binary_cache(
  prebuild_config: "Debug",
  ...
)
```

Following are the options available in `config_cocoapods_binary_cache`:

- `prebuild_config` (default: `Debug`): The configuration to use (such as `Debug`) when prebuilding pods

- `prebuild_job` (default: `false`): Whether or not this is a prebuild job

- `prebuild_all_vendor_pods` (default: `false`): Whether to build all vendor pods in the prebuild job

- `excluded_pods` (default: `[]`): A list of pods to exclude (ie. treat them as non-prebuilt pods)

- `bitcode_enabled` (default: `false`): Enable bitcode when building pods in the prebuild job

- `save_cache_validation_to` (default: `nil`): The path to save cache validation (missed/hit). Do nothing if not specified

- `validate_prebuilt_settings` (default: `nil`): Validate build settings of the prebuilt frameworks. A framework that has incompatible build settings will be treated as a cache miss. If this option is not specified, only versions of the prebuilt pods are used to check for cache hit/miss. Below is a sample build settings validation:
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
