module PodPrebuild
  class DevPodsCacheValidator < BaseCacheValidator
    def validate(*)
      return PodPrebuild::CacheValidationResult.new if @pod_lockfile.nil?

      validate_pods(
        pods: @pod_lockfile.dev_pods,
        subspec_pods: [],
        prebuilt_pods: @prebuilt_lockfile.nil? ? {} : @prebuilt_lockfile.dev_pods
      )
    end

    def incompatible_pod(name)
      diff = super(name)
      return diff unless diff.empty?

      incompatible_source(name)
    end

    def incompatible_source(name)
      diff = {}
      prebuilt_hash = read_source_hash(name)
      expected_hash = pod_lockfile.dev_pod_hash(name)
      unless prebuilt_hash == expected_hash
        diff[name] = { :prebuilt_hash => prebuilt_hash, :expected_hash => expected_hash}
      end
      diff
    end
  end
end
