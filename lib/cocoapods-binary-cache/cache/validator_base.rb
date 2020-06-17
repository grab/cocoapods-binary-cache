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

    def validate(*)
      raise NotImplementedError
    end

    def changes_of_prebuilt_lockfile_vs_podfile
      @changes_of_prebuilt_lockfile_vs_podfile ||= Pod::Installer::Analyzer::SpecsState.new(
        @prebuilt_lockfile.lockfile.detect_changes_with_podfile(@podfile)
      )
    end

    def validate_with_podfile
      changes = changes_of_prebuilt_lockfile_vs_podfile
      missed = changes.added.map { |pod| [pod, "Added from Podfile"] }.to_h
      missed.merge!(changes.changed.map { |pod| [pod, "Updated from Podfile"] }.to_h)
      PodPrebuild::CacheValidationResult.new(missed, changes.unchanged)
    end

    def validate_pods(options)
      pods = options[:pods]
      subspec_pods = options[:subspec_pods]
      prebuilt_pods = options[:prebuilt_pods]

      missed = {}
      hit = Set.new

      check_pod = lambda do |name|
        version = pods[name]
        prebuilt_version = prebuilt_pods[name]
        result = false
        if prebuilt_version.nil?
          missed[name] = "Not available (#{version})"
        elsif prebuilt_version != version
          missed[name] = "Outdated: (prebuilt: #{prebuilt_version}) vs (#{version})"
        else
          settings_diff = incompatible_build_settings(name)
          if settings_diff.empty?
            hit << name
            result = true
          else
            missed[name] = "Incompatible build settings: #{settings_diff}"
          end
        end
        result
      end

      subspec_pods.each do |parent, children|
        missed_children = children.reject { |child| check_pod.call(child) }
        if missed_children.empty?
          hit << parent
        else
          missed[parent] = "Subspec pods were missed: #{missed_children}"
        end
      end

      non_subspec_pods = pods.reject { |pod| subspec_pods.include?(pod) }
      non_subspec_pods.each { |pod, _| check_pod.call(pod) }
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
        unless prebuilt_value.nil? || value == prebuilt_value
          settings_diff[key] = { :current => value, :prebuilt => prebuilt_value }
        end
      end
      settings_diff
    end
  end
end
