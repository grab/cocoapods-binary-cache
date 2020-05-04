module PodPrebuild
  class CacheValidator
    attr_reader :pod_lockfile, :prebuilt_lockfile

    def initialize(pod_lockfile, prebuilt_lockfile)
      @pod_lockfile = pod_lockfile.nil? ? nil : PodPrebuild::Lockfile.new(pod_lockfile)
      @prebuilt_lockfile = prebuilt_lockfile.nil? ? nil : PodPrebuild::Lockfile.new(prebuilt_lockfile)
      # TODO (thuyen): Add prebuilt metadata
    end

    def validate
      validate_non_dev_pods
    end

    private

    def validate_non_dev_pods
      missed = {} # A mapping of { frameworking_name => missing_reason }
      hit = Set.new
      return PodPrebuild::CacheValidationResult.new(missed, hit) if @pod_lockfile.nil?

      prebuilt_non_dev_pods = @prebuilt_lockfile.nil? ? {} : @prebuilt_lockfile.non_dev_pods
      @pod_lockfile.non_dev_pods.each do |name, version|
        prebuilt_version = prebuilt_non_dev_pods[name]
        if prebuilt_version.nil?
          missed[name] = "Not available (#{version})"
        elsif prebuilt_version != version
          missed[name] = "Outdated: (prebuilt: #{prebuilt_version}) vs (#{version})"
        elsif !compatible_build_settings(name)
          missed[name] = "Incompatible build settings"
        else
          hit << name
        end
      end
      PodPrebuild::CacheValidationResult.new(missed, hit)
    end

    def compatible_build_settings(*)
      true # TODO (thuyen): Implement this
    end
  end
end
