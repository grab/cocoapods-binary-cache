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
      @ignored_pods = options[:ignored_pods] || Set.new
    end

    def validate
      raise NotImplementedError
    end

    def changes_of_prebuilt_lockfile_vs_podfile
      @changes_of_prebuilt_lockfile_vs_podfile ||= Pod::Installer::Analyzer::SpecsState.new(
        @prebuilt_lockfile.lockfile.detect_changes_with_podfile(@podfile)
      )
    end

    def validate_with_podfile
      return PodPrebuild::CacheValidationResult.new({}, Set.new) if @prebuilt_lockfile.nil? || @podfile.nil?

      changes = changes_of_prebuilt_lockfile_vs_podfile
      missed = changes.added.map { |pod| [pod, "Added from Podfile"] }.to_h
      missed.merge!(changes.changed.map { |pod| [pod, "Updated from Podfile"] }.to_h)
      PodPrebuild::CacheValidationResult.new(missed, changes.unchanged).exclude_pods(@ignored_pods)
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
