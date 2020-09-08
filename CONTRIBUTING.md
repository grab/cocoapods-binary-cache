# Contributing

You are more than welcome to contribute to this repo regardless of whether it is a change in the codebase or just a reported issue.

## Report an issue

When reporting the issue, kindly describe:
- The [cococoapods-binary-cache](https://github.com/grab/cocoapods-binary-cache/tags) gem version you are using
- The prebuild configuration (if possible), including:
  - The `PodBinaryCacheConfig.json` contents
  - The setup code in Podfile:
  ```rb
  config_cocoapods_binary_cache(
    prebuild_config: "Debug",
    ...
  )
  ```
- If possible, please help reproduce the issue with a demo project if the issue is related to some strange build issues.

## Contribute to the codebase

Do note that the Github repo [cococoapods-binary-cache](https://github.com/grab/cocoapods-binary-cache) is a mirror of an internal repo.

If you are a Grabber or you have access to the internal repo, kindly submit your change to this internal repo.

In case you do not have access to this repo, please check out the following steps:

1. Submit your change to the Github repo [cococoapods-binary-cache](https://github.com/grab/cocoapods-binary-cache).
2. The change is reviewed by our team.
3. Once the change is approved, we'll proceed to merge your change.

...

Look forward to your contribution! 😉
