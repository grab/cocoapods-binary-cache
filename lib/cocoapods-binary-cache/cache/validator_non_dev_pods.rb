module PodPrebuild
  class NonDevPodsCacheValidator < BaseCacheValidator
    def validate
      return validate_with_podfile.exclude_pods(@ignored_pods) if @pod_lockfile.nil?

      validate_pods(
        pods: @pod_lockfile.non_dev_pods,
        subspec_pods: @pod_lockfile.subspec_pods,
        prebuilt_pods: @prebuilt_lockfile.nil? ? {} : @prebuilt_lockfile.non_dev_pods
      ).merge(validate_with_podfile).exclude_pods(@ignored_pods)
    end
  end
end
