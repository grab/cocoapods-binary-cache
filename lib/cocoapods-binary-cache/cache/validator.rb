module PodPrebuild
  class CacheValidator
    attr_reader :pod_lockfile, :prebuilt_lockfile
    attr_reader :validate_prebuilt_settings, :generated_framework_path

    def initialize(options)
      @pod_lockfile = options[:pod_lockfile] && PodPrebuild::Lockfile.new(options[:pod_lockfile])
      @prebuilt_lockfile = options[:prebuilt_lockfile] && PodPrebuild::Lockfile.new(options[:prebuilt_lockfile])
      @validate_prebuilt_settings = options[:validate_prebuilt_settings]
      @generated_framework_path = options[:generated_framework_path]
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
        else
          settings_diff = incompatible_build_settings(name)
          if settings_diff.empty?
            hit << name
          else
            missed[name] = "Incompatible build settings: #{settings_diff}"
          end
        end
      end
      PodPrebuild::CacheValidationResult.new(missed, hit)
    end

    def read_prebuilt_build_settings(name)
      return {} if generated_framework_path.nil?

      metadata = PodPrebuild::Metadata.in_dir(generated_framework_path + name)
      metadata.build_settings
    end

    def incompatible_build_settings(name)
      settings_diff = {}
      prebuilt_build_settings = read_prebuilt_build_settings(name)
      validate_prebuilt_settings&.(name)&.each do |key, value|
        prebuilt_value = prebuilt_build_settings[key]
        settings_diff[key] = { :current => value, :prebuilt => prebuilt_value } unless value == prebuilt_value
      end
      settings_diff
    end
  end
end
