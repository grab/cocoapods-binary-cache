module PodPrebuild
  class NonDevPodsCacheValidator < BaseCacheValidator
    def validate(*)
      return PodPrebuild::CacheValidationResult.new if @pod_lockfile.nil?

      validate_pods(
        pods: @pod_lockfile.non_dev_pods,
        subspec_pods: @pod_lockfile.subspec_vendor_pods,
        prebuilt_pods: @prebuilt_lockfile.nil? ? {} : @prebuilt_lockfile.non_dev_pods
      )
    end
  end
end
