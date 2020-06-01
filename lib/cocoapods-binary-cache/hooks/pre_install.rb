module PodPrebuild
  class PreInstallHook
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
      return if Pod.is_prebuild_stage

      log_section "🚀  Prebuild frameworks"
      ensure_valid_podfile
      save_pod_install_options
      prepare_environment
      create_prebuild_sandbox
      validate_cache
      install!
      reset_environment
      log_section "🤖  Resume pod installation"
      require_relative "../pod-binary/integration"
    end

    private

    def save_pod_install_options
      # Fetch original installer (which is running this pre-install hook) options,
      # then pass them to our installer to perform update if needed
      # Looks like this is the most appropriate way to figure out that something should be updated
      original_installer = ObjectSpace.each_object(Pod::Installer).first
      @pod_install_options[:update] = original_installer.update
      @pod_install_options[:repo_update] = original_installer.repo_update
    end

    def ensure_valid_podfile
      podfile.target_definition_list.each do |target_definition|
        next if target_definition.prebuild_framework_pod_names.empty?

        unless target_definition.uses_frameworks?
          warn "[!] Cocoapods-binary requires `use_frameworks!`".red
          exit
        end
      end
    end

    def prepare_environment
      Pod::UI.puts "Prepare environment"
      Pod.is_prebuild_stage = true
      Pod::Podfile::DSL.enable_prebuild_patch true  # enable sikpping for prebuild targets
      Pod::Installer.force_disable_integration true # don't integrate targets
      Pod::Config.force_disable_write_lockfile true # disbale write lock file for perbuild podfile
      Pod::Installer.disable_install_complete_message true # disable install complete message
    end

    def reset_environment
      Pod::UI.puts "Reset environment"
      Pod.is_prebuild_stage = false
      Pod::Installer.force_disable_integration false
      Pod::Podfile::DSL.enable_prebuild_patch false
      Pod::Config.force_disable_write_lockfile false
      Pod::Installer.disable_install_complete_message false
      Pod::UserInterface.warnings = [] # clean the warning in the prebuild step, it's duplicated.
    end

    def create_prebuild_sandbox
      standard_sandbox = installer_context.sandbox
      @prebuild_sandbox = Pod::PrebuildSandbox.from_standard_sandbox(standard_sandbox)
      Pod::UI.puts "Create prebuild sandbox at #{@prebuild_sandbox.root}"
    end

    def validate_cache
      prebuilt_lockfile = Pod::Lockfile.from_file(prebuild_sandbox.root + "Manifest.lock")
      @cache_validation = PodPrebuild::CacheValidator.new(
        podfile: Pod::Podfile.from_ruby(podfile.defined_in_file),
        pod_lockfile: installer_context.lockfile,
        prebuilt_lockfile: prebuilt_lockfile,
        validate_prebuilt_settings: Pod::Podfile::DSL.validate_prebuilt_settings,
        generated_framework_path: prebuild_sandbox.generate_framework_path
      ).validate
      cache_validation.print_summary
      cachemiss_vendor_pods = cache_validation.missed
      cachehit_vendor_pods = cache_validation.hit

      # TODO (thuyen): Avoid global mutation
      Pod::Prebuild::CacheInfo.cache_hit_vendor_pods = cachehit_vendor_pods
      Pod::Podfile::DSL.add_unbuilt_pods(cachemiss_vendor_pods) unless Pod::Podfile::DSL.is_prebuild_job

      # Verify Dev pod cache
      if Pod::Podfile::DSL.enable_prebuild_dev_pod
        BenchmarkShow.benchmark do
          cachemiss_pods_dic, cachehit_pods_dic = PodCacheValidator.verify_devpod_checksum(
            prebuild_sandbox,
            installer_context.lockfile
          )
          Pod::Prebuild::CacheInfo.cache_hit_dev_pods_dic = cachehit_pods_dic
          Pod::Prebuild::CacheInfo.cache_miss_dev_pods_dic = cachemiss_pods_dic
        end
        unless Pod::Podfile::DSL.is_prebuild_job
          Pod::Podfile::DSL.add_unbuilt_pods(Pod::Prebuild::CacheInfo.cache_miss_dev_pods_dic.keys)
        end
      end

      # Will remove after migrating all libraries to Swift 5 + Xcode 11 + support LIBRARY EVOLUTION
      return if library_evolution_supported?
      return if installer_context.lockfile.nil?

      dependencies_graph = DependenciesGraph.new(installer_context.lockfile)
      vendor_pods_clients, devpod_clients_of_vendorpods = dependencies_graph
        .get_clients(cachemiss_vendor_pods.to_a)
        .partition { |name| cachehit_vendor_pods.include?(name) }
      dev_pods_clients = dependencies_graph
        .get_clients(Pod::Prebuild::CacheInfo.cache_miss_dev_pods_dic.keys) \
          + devpod_clients_of_vendorpods
      Pod::UI.puts "Vendor pod cache miss: #{cachemiss_vendor_pods.to_a} \n=> clients: #{vendor_pods_clients.to_a}"
      Pod::UI.puts "Dev pod cache-miss: #{Pod::Prebuild::CacheInfo.cache_miss_dev_pods_dic.keys} \n=> clients #{dev_pods_clients.to_a}"

      Pod::Prebuild::CacheInfo.cache_hit_vendor_pods -= vendor_pods_clients
      dev_pods_clients.each do |name|
        value = Pod::Prebuild::CacheInfo.cache_hit_dev_pods_dic[name]
        next unless value

        Pod::Prebuild::CacheInfo.cache_hit_dev_pods_dic.delete(name)
        Pod::Prebuild::CacheInfo.cache_miss_dev_pods_dic[name] = value
      end
      unless Pod::Podfile::DSL.is_prebuild_job
        Pod::Podfile::DSL.add_unbuilt_pods(vendor_pods_clients)
        Pod::Podfile::DSL.add_unbuilt_pods(dev_pods_clients)
      end

      # For debugging
      cachemiss_libs = cachemiss_vendor_pods + vendor_pods_clients + Pod::Prebuild::CacheInfo.cache_miss_dev_pods_dic.keys
      Pod::UI.puts "Cache miss libs: #{cachemiss_libs.count} \n #{cachemiss_libs.to_a}"
    end

    def install!
      binary_installer = Pod::PrebuildInstaller.new(
        sandbox: prebuild_sandbox,
        podfile: Pod::Podfile.from_ruby(podfile.defined_in_file),
        lockfile: installer_context.lockfile,
        cache_validation: cache_validation
      )

      binary_installer.clean_delta_file

      installer_exec = lambda do
        binary_installer.update = @pod_install_options[:update]
        binary_installer.repo_update = @pod_install_options[:repo_update]
        binary_installer.install!
      end

      # TODO (Vince): Do not mutate Pod::Podfile::DSL as it's reloaded
      # when creating an installer (Pod::Installer)
      Pod::Podfile::DSL.add_unbuilt_pods(cache_validation.missed) unless Pod::Podfile::DSL.is_prebuild_job

      if Pod::Podfile::DSL.prebuild_all_vendor_pods
        Pod::UI.puts "Prebuild all vendor pods"
        installer_exec.call
      elsif !@pod_install_options[:update] && cache_validation.missed.empty?
        # If not in prebuild job, we never rebuild and just use cache
        Pod::UI.puts "Cache hit"
        binary_installer.install_when_cache_hit!
      else
        Pod::UI.puts "Cache miss -> need to update: #{cache_validation.missed.to_a}"
        installer_exec.call
      end
    end

    def log_section(message)
      Pod::UI.puts "-----------------------------------------"
      Pod::UI.puts message
      Pod::UI.puts "-----------------------------------------"
    end

    def library_evolution_supported?
      false
    end
  end
end
