require_relative 'helper/podfile_options'
require_relative 'helper/passer'
require_relative '../helper/benchmark_show'
require_relative '../prebuild_cache'
require_relative '../scheme_editor'
require_relative '../dependencies_graph/dependencies_graph'

SUPPORTED_LIBRARY_EVOLUTION = false

Pod::HooksManager.register("cocoapods-binary-cache", :pre_install) do |installer_context|
  require_relative "helper/feature_switches"
  if Pod.is_prebuild_stage
    next
  end

  # [Check Environment]
  # check user_framework is on
  podfile = installer_context.podfile
  podfile.target_definition_list.each do |target_definition|
    next if target_definition.prebuild_framework_pod_names.empty?
    if not target_definition.uses_frameworks?
      STDERR.puts "[!] Cocoapods-binary requires `use_frameworks!`".red
      exit
    end
  end

  # -- step 1: prebuild framework ---
  # Execute a sperated pod install, to generate targets for building framework,
  # then compile them to framework files.
  require_relative "helper/prebuild_sandbox"
  require_relative "prebuild"

  Pod::UI.puts "🚀  Prebuild frameworks"

  # Fetch original installer (which is running this pre-install hook) options,
  # then pass them to our installer to perform update if needed
  # Looks like this is the most appropriate way to figure out that something should be updated

  update = nil
  repo_update = nil

  include ObjectSpace
  ObjectSpace.each_object(Pod::Installer) { |installer|
    update = installer.update
    repo_update = installer.repo_update
  }

  # control features
  Pod::UI.puts "control features"
  Pod.is_prebuild_stage = true
  Pod::Podfile::DSL.enable_prebuild_patch true  # enable sikpping for prebuild targets
  Pod::Installer.force_disable_integration true # don't integrate targets
  Pod::Config.force_disable_write_lockfile true # disbale write lock file for perbuild podfile
  Pod::Installer.disable_install_complete_message true # disable install complete message

  # make another custom sandbox
  Pod::UI.puts "make another custom sandbox"
  standard_sandbox = installer_context.sandbox
  prebuild_sandbox = Pod::PrebuildSandbox.from_standard_sandbox(standard_sandbox)

  # get the podfile for prebuild
  Pod::UI.puts "get the podfile for prebuild"
  prebuild_podfile = Pod::Podfile.from_ruby(podfile.defined_in_file)

  # install
  lockfile = installer_context.lockfile
  binary_installer = Pod::Installer.new(prebuild_sandbox, prebuild_podfile, lockfile)

  # Verify Vendor pod cache
  manifest_path = prebuild_sandbox.root + "Manifest.lock"
  prebuilt_lockfile = Pod::Lockfile.from_file Pathname.new(manifest_path)
  cachemiss_vendor_pods, cachehit_vendor_pods = PodCacheValidator.verify_prebuilt_vendor_pods(lockfile, prebuilt_lockfile)
  Pod::Prebuild::CacheInfo.cache_hit_vendor_pods = cachehit_vendor_pods
  if !Pod::Podfile::DSL.is_prebuild_job
    Pod::Podfile::DSL.add_unbuilt_pods(cachemiss_vendor_pods)
  end

  # Verify Dev pod cache
  if Pod::Podfile::DSL.enable_prebuild_dev_pod
    BenchmarkShow.benchmark {
      cachemiss_pods_dic, cachehit_pods_dic = PodCacheValidator.verify_devpod_checksum(prebuild_sandbox, lockfile)
      Pod::Prebuild::CacheInfo.cache_hit_dev_pods_dic = cachehit_pods_dic
      Pod::Prebuild::CacheInfo.cache_miss_dev_pods_dic = cachemiss_pods_dic
    }
    if !Pod::Podfile::DSL.is_prebuild_job
      Pod::Podfile::DSL.add_unbuilt_pods(Pod::Prebuild::CacheInfo.cache_miss_dev_pods_dic.keys)
    end
  end

  if !SUPPORTED_LIBRARY_EVOLUTION # Will remove after migrating all libraries to Swift 5 + Xcode 11 + support LIBRARY EVOLUTION
    dependencies_graph = DependenciesGraph.new(lockfile)
    vendor_pods_clients, devpod_clients_of_vendorpods = dependencies_graph.get_clients(cachemiss_vendor_pods.to_a).partition { |name| cachehit_vendor_pods.include?(name) }
    dev_pods_clients = dependencies_graph.get_clients(Pod::Prebuild::CacheInfo.cache_miss_dev_pods_dic.keys) + devpod_clients_of_vendorpods
    Pod::UI.puts "Vendor pod cache miss: #{cachemiss_vendor_pods.to_a} \n=> clients: #{vendor_pods_clients.to_a}"
    Pod::UI.puts "Dev pod cache-miss: #{Pod::Prebuild::CacheInfo.cache_miss_dev_pods_dic.keys} \n=> clients #{dev_pods_clients.to_a}"

    Pod::Prebuild::CacheInfo.cache_hit_vendor_pods -= vendor_pods_clients
    dev_pods_clients.each do |name|
      value = Pod::Prebuild::CacheInfo.cache_hit_dev_pods_dic[name]
      next if !value

      Pod::Prebuild::CacheInfo.cache_hit_dev_pods_dic.delete(name)
      Pod::Prebuild::CacheInfo.cache_miss_dev_pods_dic[name] = value
    end
    if !Pod::Podfile::DSL.is_prebuild_job
      Pod::Podfile::DSL.add_unbuilt_pods(vendor_pods_clients)
      Pod::Podfile::DSL.add_unbuilt_pods(dev_pods_clients)
    end

    # For debugging
    cachemiss_libs = cachemiss_vendor_pods + vendor_pods_clients + Pod::Prebuild::CacheInfo.cache_miss_dev_pods_dic.keys
    Pod::UI.puts "Cache miss libs: #{cachemiss_libs.count} \n #{cachemiss_libs.to_a}"
    # dependencies_graph.write_graphic_file('png', filename='graph', highlight_nodes=cachemiss_libs)
  end

  binary_installer.clean_delta_file

  installer_exec = lambda do
    binary_installer.update = update
    binary_installer.repo_update = repo_update
    binary_installer.install!
  end

  # Currently, `binary_installer.cache_miss` depends on the output of `Pod::Podfile::DSL.unbuilt_pods`
  # -> indirectly depends on:
  #   - `PodCacheValidator.verify_prebuilt_vendor_pods`
  #   - `PodCacheValidator.verify_devpod_checksum`
  # TODO (thuyen): Simplify this logic
  cache_miss = binary_installer.cache_miss
  Pod::Podfile::DSL.add_unbuilt_pods(cache_miss)

  if Pod::Podfile::DSL.prebuild_all_vendor_pods
    Pod::UI.puts "Prebuild all vendor pods"
    installer_exec.call
  elsif !update && cache_miss.empty? # If not in prebuild job, we never rebuild and just use cache
    Pod::UI.puts "Cache hit"
    binary_installer.install_when_cache_hit!
  else
    Pod::UI.puts "Cache miss -> need to update"
    installer_exec.call
  end

  # reset the environment
  Pod.is_prebuild_stage = false
  Pod::Installer.force_disable_integration false
  Pod::Podfile::DSL.enable_prebuild_patch false
  Pod::Config.force_disable_write_lockfile false
  Pod::Installer.disable_install_complete_message false
  Pod::UserInterface.warnings = [] # clean the warning in the prebuild step, it's duplicated.

  # -- step 2: pod install ---
  # install
  Pod::UI.puts "\n"
  Pod::UI.puts "🤖  Pod Install"
  require_relative "integration"
  # go on the normal install step ...
end

Pod::HooksManager.register("cocoapods-binary-cache", :post_install) do |installer_context|
  next unless Pod::Podfile::DSL.enable_prebuild_dev_pod and installer_context.sandbox.instance_of?(Pod::PrebuildSandbox)

  # Modify pods scheme to support code coverage
  # If we don't prebuild dev pod -> no need to care about this in Pod project because we setup in the main project. Eg. DriverCI scheme
  if Pod.is_prebuild_stage
    SchemeEditor.edit_to_support_code_coverage(installer_context.sandbox)
  end
end
