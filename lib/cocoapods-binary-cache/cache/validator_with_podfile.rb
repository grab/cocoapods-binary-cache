module PodPrebuild
  class PodfileChangesCacheValidator < BaseCacheValidator
    def validate(*)
      return PodPrebuild::CacheValidationResult.new if @prebuilt_lockfile.nil? || @podfile.nil?

      validation = validate_with_podfile
      unless Pod::Podfile::DSL.dev_pods_enabled
        dev_pods_in_podfile = @podfile.dependencies.select(&:local?).map(&:name)
        dev_pods_in_prebuilt_lockfile = @prebuilt_lockfile.nil? ? [] : @prebuilt_lockfile.dev_pod_names.to_a
        return validation.exclude_pods(dev_pods_in_podfile + dev_pods_in_prebuilt_lockfile)
      end
      validation
    end
  end
end
