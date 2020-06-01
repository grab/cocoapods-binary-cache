module PodPrebuild
  class BaseCacheValidator
    attr_reader :podfile, :pod_lockfile, :prebuilt_lockfile
    attr_reader :validate_prebuilt_settings, :generated_framework_path

    def initialize(options)
      @podfile = options[:podfile]
      @pod_lockfile = options[:pod_lockfile] && PodPrebuild::Lockfile.new(options[:pod_lockfile])
      @prebuilt_lockfile = options[:prebuilt_lockfile] && PodPrebuild::Lockfile.new(options[:prebuilt_lockfile])
      @validate_prebuilt_settings = options[:validate_prebuilt_settings]
      @generated_framework_path = options[:generated_framework_path]
    end

    def validate
      raise NotImplementedError
    end

    def pods_from_podfile
      raw_changes = @prebuilt_lockfile.lockfile.detect_changes_with_podfile(@podfile)
      changes = Pod::Installer::Analyzer::SpecsState.new(raw_changes)
      changes.added + changes.changed + changes.unchanged
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
        unless prebuilt_value.nil? || value == prebuilt_value
          settings_diff[key] = { :current => value, :prebuilt => prebuilt_value }
        end
      end
      settings_diff
    end
  end
end
