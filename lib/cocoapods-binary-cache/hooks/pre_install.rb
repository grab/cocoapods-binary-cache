module PodPrebuild
  class PreInstallHook # rubocop:disable Metrics/ClassLength
    include ObjectSpace

    attr_reader :installer_context, :podfile, :prebuild_sandbox, :cache_validation

    def initialize(installer_context)
      @installer_context = installer_context
      @podfile = installer_context.podfile
      @pod_install_options = {}
      @prebuild_sandbox = nil
      @cache_validation = nil
    end

    def run
      return if @installer_context.sandbox.is_a?(Pod::PrebuildSandbox)

      require_relative "../pod-binary/helper/feature_switches"

      log_section "🚀  Prebuild frameworks"
      ensure_valid_podfile
      save_installation_states
      prepare_environment
      create_prebuild_sandbox
      Pod::UI.title("Detect implicit dependencies") { detect_implicit_dependencies }
      Pod::UI.title("Validate prebuilt cache") { validate_cache }
      prebuild! if PodPrebuild.config.prebuild_job?
      reset_environment

      PodPrebuild::Env.next_stage!
      log_section "🤖  Resume pod installation"
      require_relative "../pod-binary/integration"
    end

    private

    def save_installation_states
      save_pod_install_options
    end

    def save_pod_install_options
      # Fetch original installer (which is running this pre-install hook) options,
      # then pass them to our installer to perform update if needed
      # Looks like this is the most appropriate way to figure out that something should be updated
      @original_installer = ObjectSpace.each_object(Pod::Installer).first
      @pod_install_options[:update] = @original_installer.update
      @pod_install_options[:repo_update] = @original_installer.repo_update
    end

    def ensure_valid_podfile
      podfile.target_definition_list.each do |target_definition|
        next if target_definition.explicit_prebuilt_pod_names.empty?
        raise "cocoapods-binary-cache requires `use_frameworks!`" unless target_definition.uses_frameworks?
      end
    end

    def prepare_environment
      Pod::Installer.force_disable_integration true # don't integrate targets
      Pod::Config.force_disable_write_lockfile true # disbale write lock file for perbuild podfile
      Pod::Installer.disable_install_complete_message true # disable install complete message
    end

    def reset_environment
      Pod::Installer.force_disable_integration false
      Pod::Config.force_disable_write_lockfile false
      Pod::Installer.disable_install_complete_message false
      Pod::UserInterface.warnings = [] # clean the warning in the prebuild step, it's duplicated.
    end

    def create_prebuild_sandbox
      standard_sandbox = installer_context.sandbox
      @prebuild_sandbox = Pod::PrebuildSandbox.from_standard_sandbox(standard_sandbox)
      Pod::UI.message "Create prebuild sandbox at #{@prebuild_sandbox.root}"
    end

    def detect_implicit_dependencies
      @original_installer.resolve_dependencies
      all_specs = @original_installer.analysis_result.specifications
      pods_with_empty_source_files = all_specs
        .group_by { |spec| spec.name.split("/")[0] }
        .select { |_, specs| specs.all?(&:empty_source_files?) }
        .keys
      PodPrebuild.config.update_detected_excluded_pods!(pods_with_empty_source_files)
      PodPrebuild.config.update_detected_prebuilt_pod_names!(@original_installer.prebuilt_pod_names)
      Pod::UI.puts "Exclude pods with empty source files: #{pods_with_empty_source_files.to_a}"
    end

    def validate_cache
      prebuilt_lockfile = Pod::Lockfile.from_file(prebuild_sandbox.root + "Manifest.lock")
      @cache_validation = PodPrebuild::CacheValidator.new(
        podfile: podfile,
        pod_lockfile: installer_context.lockfile,
        prebuilt_lockfile: prebuilt_lockfile,
        validate_prebuilt_settings: PodPrebuild.config.validate_prebuilt_settings,
        generated_framework_path: prebuild_sandbox.generate_framework_path,
        sandbox_root: prebuild_sandbox.root,
        ignored_pods: PodPrebuild.config.excluded_pods,
        prebuilt_pod_names: PodPrebuild.config.prebuilt_pod_names
      ).validate
      path_to_save_cache_validation = PodPrebuild.config.save_cache_validation_to
      @cache_validation.update_to(path_to_save_cache_validation) unless path_to_save_cache_validation.nil?
      cache_validation.print_summary
      PodPrebuild.state.update(:cache_validation => cache_validation)
    end

    def prebuild!
      binary_installer = Pod::PrebuildInstaller.new(
        sandbox: prebuild_sandbox,
        podfile: podfile,
        lockfile: installer_context.lockfile,
        cache_validation: cache_validation
      )
      binary_installer.update = @pod_install_options[:update]
      binary_installer.repo_update = @pod_install_options[:repo_update]

      Pod::UI.title("Prebuilding...") do
        binary_installer.clean_delta_file
        binary_installer.install!
      end
    end

    def log_section(message)
      Pod::UI.puts "-----------------------------------------"
      Pod::UI.puts message
      Pod::UI.puts "-----------------------------------------"
    end
  end
end
