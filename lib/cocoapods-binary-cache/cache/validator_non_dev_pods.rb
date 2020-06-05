module PodPrebuild
  class NonDevPodsCacheValidator < BaseCacheValidator
    def validate
      return validate_with_podfile if @pod_lockfile.nil?

      missed = {} # A mapping of { frameworking_name => missing_reason }
      hit = Set.new

      prebuilt_non_dev_pods = @prebuilt_lockfile.nil? ? {} : @prebuilt_lockfile.non_dev_pods
      @pod_lockfile.non_dev_pods.each do |name, version|
        prebuilt_version = prebuilt_non_dev_pods[name]
        if prebuilt_version.nil?
          missed[name] = "Not available (#{version})"
        elsif prebuilt_version != version
          missed[name] = "Outdated: (prebuilt: #{prebuilt_version}) vs (#{version})"
        else
          settings_diff = incompatible_build_settings(name)
          if settings_diff.empty?
            hit << name
          else
            missed[name] = "Incompatible build settings: #{settings_diff}"
          end
        end
      end
      validate_with_podfile.merge(PodPrebuild::CacheValidationResult.new(missed, hit)).exclude_pods(@ignored_pods)
    end
  end
end
