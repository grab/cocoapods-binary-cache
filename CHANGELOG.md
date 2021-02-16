# Changelog

## master (to be 0.1.14)
### Enhancements
NA

### Bug fixes
NA

## 0.1.13
### Enhancements
- Don't add Pods project of the prebuild sandbox to the workspace https://github.com/grab/cocoapods-binary-cache/issues/56.

### Bug fixes
- Fix `readlink` https://github.com/grab/cocoapods-binary-cache/issues/49. Kudos to [Roger Oba](https://github.com/rogerluan)

## 0.1.12
### Enhancements
- Speed up cache unzip by running them in parallel.
- Remove the `still_download_sources` option. Instead, always download sources to avoid improper integration.
- Add `xcframework` support (instead of creating fat framework with `lipo`) https://github.com/grab/cocoapods-binary-cache/issues/54.
- dSYMs and BCSymbolMaps for `xcframework`. Kudos to [Kien Nguyen](https://github.com/kientux).

### Bug fixes
- Fix resources integration (for ex. using `SwiftDate` as a static framework).

## 0.1.11
### Enhancements
- Support local cache dir https://github.com/grab/cocoapods-binary-cache/issues/31.

### Bug fixes
- Project path was not escaped in the `xcodebuild` command.
- By default, should set `ONLY_ACTIVE_ARCH=NO` when building for devices.

## 0.1.10
### Enhancements
- Add option `--no-fetch` to the `prebuild` command.

### Bug fixes
- Sources of external-sources pods are not fetched properly in incremental pod installation. It should use the checkout options declared in Podfile instead.
- Conflict definition of `xcodebuild` in this plugin and in `cocoapods-rome` causing prebuild failures https://github.com/grab/cocoapods-binary-cache/issues/36.

## 0.1.9
### Enhancements
- Provide an option to keep sources downloading behavior, useful for maintaining the `preserve_paths` of the podspecs.

### Bug fixes
- Handle git failures properly (throwing errors if any).

## 0.1.8
### Enhancements
- Prebuild multiple targets concurently to ultilize build parallelism.

### Bug fixes
- Abnormal integration when some prebuilt pods are detected as unchanged in the integration step https://github.com/grab/cocoapods-binary-cache/issues/21.
- Wrong merge of `Info.plist` when prebuilding for simulators and devices https://github.com/grab/cocoapods-binary-cache/issues/25.
- Cache validation when subspecs have empty source but the parent spec does have sources (https://github.com/grab/cocoapods-binary-cache/pull/26). Kudos to Christian Nadeau.

---
## 0.1.7
### Enhancements
- Change the prebuilt path from `Pods/A/A.framework` to `Pods/A/_Prebuilt/A.framework`. No config change is required.
- Show warnings if there exists an inapplicable option in `config_cocoapods_binary_cache`.
- Deprecate configs (`cache_repo`, `cache_path`, `prebuild_path`...) in `PodBinaryCacheConfig.json`. Rather, declare them in `config_cocoapods_binary_cache`. Refer to [Configure cocoapods-binary-cache](/docs/configure_cocoapods_binary_cache.md) for more details.
- Multi-cache-repo support https://github.com/grab/cocoapods-binary-cache/issues/18.

### Bug fixes
None

---
## 0.1.6
### Enhancements
- Remove the `prebuild_all_vendor_pods` option. Specify this in the CLI instead: `pod binary prebuild --all`
- Allow prebuilding specific targets: `pod binary prebuild --targets=A,B,C`
- Provide an option to run code generation for prebuild. Refer to the [`prebuild_code_gen` option](/docs/configure_cocoapods_binary_cache.md).

### Bug fixes
- Exclude files ignored by git when calculating checksums for development pods.
- Exception thrown when `Podfile.lock` is not present https://github.com/grab/cocoapods-binary-cache/issues/20.

---
## 0.1.5
### Enhancements
- Enable device support when prebuild frameworks https://github.com/grab/cocoapods-binary-cache/issues/19. Refer to the [`device_build_enabled` option](/docs/configure_cocoapods_binary_cache.md).

### Bug fixes
None

---
## 0.1.4
### Enhancements
- Allow specifying the prebuild sandbox path (default as `_Prebuild`, previously as `Pods/_Prebuild`).
- Add diagnosis action to spot unintegrated prebuilt frameworks.
- Preparation work for development pods supported.

### Bug fixes
- Missing `push` command in the CLI: `pod binary push`
- Exception thrown when requirements of a pod are not specified https://github.com/grab/cocoapods-binary-cache/pull/17. Kudos to [Mack Hasz](https://github.com/lazyvar).

---
## 0.1.3
### Enhancements
- No need to specify `prebuild_job` in the `config_cocoapods_binary_cache` in a prebuild job.

### Bug fixes
None

---
## 0.1.2
### Enhancements
None

### Bug fixes
- Corrupted cache zip/unzip if there are symlinks inside the framework.

---
## 0.1.1
### Enhancements
- Enhance cache validation mechanism.
- Update DSL: use `config_cocoapods_binary_cache` for cocoapods-binary-cache related configs.
- Validate build settings (for ex. changing a framework from `dynamic` to `static` is considered cache-missed).
- Auto-exclude frameworks with no source (for ex. originally distributed as prebuilt).
- Detect dependencies of pods explicitly declared as prebuilt and treat them as prebuilt.

### Bug fixes
- Various fixes for static frameworks:
  - Resources bundle not integrated properly.
  - XIB resources not integrated properly https://github.com/grab/cocoapods-binary-cache/issues/7.
- Various fixes for cache validation with subspecs.

---
## 0.0.1 - 0.0.5
- Initially released on 2019-12-20 🎉 (0.0.1).
