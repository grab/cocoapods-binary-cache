# encoding: UTF-8
require_relative 'helper/podfile_options'
require_relative 'tool/tool'
require_relative 'helper/benchmark_show'
require_relative 'helper/passer'
require_relative 'PrebuildCache'

module Pod    
    class Podfile
        module DSL
            
            # Enable prebuiding for all pods
            # it has a lower priority to other binary settings
            def all_binary!
                DSL.prebuild_all = true
            end

            # Enable bitcode for prebuilt frameworks
            def enable_bitcode_for_prebuilt_frameworks!
                DSL.bitcode_enabled = true
            end

            # Don't remove source code of prebuilt pods
            # It may speed up the pod install if git didn't 
            # include the `Pods` folder
            def keep_source_code_for_prebuilt_frameworks!
                DSL.dont_remove_source_code = true
            end

            # Add custom xcodebuild option to the prebuilding action
            #
            # You may use this for your special demands. For example: the default archs in dSYMs 
            # of prebuilt frameworks is 'arm64 armv7 x86_64', and no 'i386' for 32bit simulator.
            # It may generate a warning when building for a 32bit simulator. You may add following
            # to your podfile
            # 
            #  ` set_custom_xcodebuild_options_for_prebuilt_frameworks :simulator => "ARCHS=$(ARCHS_STANDARD)" `
            #
            # Another example to disable the generating of dSYM file:
            #
            #  ` set_custom_xcodebuild_options_for_prebuilt_frameworks "DEBUG_INFORMATION_FORMAT=dwarf"`
            # 
            #
            # @param [String or Hash] options
            #
            #   If is a String, it will apply for device and simulator. Use it just like in the commandline.
            #   If is a Hash, it should be like this: { :device => "XXXXX", :simulator => "XXXXX" }
            #
            def set_custom_xcodebuild_options_for_prebuilt_frameworks(options)
                if options.kind_of? Hash
                    DSL.custom_build_options = [ options[:device] ] unless options[:device].nil?
                    DSL.custom_build_options_simulator = [ options[:simulator] ] unless options[:simulator].nil?
                elsif options.kind_of? String
                    DSL.custom_build_options = [options]
                    DSL.custom_build_options_simulator = [options]
                else
                    raise "Wrong type."
                end
            end

            def enable_devpod_prebuild
                DSL.enable_prebuild_dev_pod = true
            end

            def set_unbuilt_dev_pods(list)
                DSL.unbuilt_dev_pods = Set.new(list)
                DSL.unbuilt_pods = DSL.unbuilt_vendor_pods.merge(DSL.unbuilt_dev_pods)
            end

            def set_is_prebuild_job(flag)
                DSL.is_prebuild_job = flag
            end

            def set_unbuilt_vendor_pods(list)
                DSL.unbuilt_vendor_pods = Set.new(list)
                DSL.unbuilt_pods = DSL.unbuilt_vendor_pods.merge(DSL.unbuilt_dev_pods)
            end

            private
            def self.add_unbuilt_pods(list)
                DSL.unbuilt_pods = DSL.unbuilt_pods.merge(list)
            end

            private
            class_attr_accessor :prebuild_all
            prebuild_all = false

            class_attr_accessor :bitcode_enabled
            bitcode_enabled = false

            class_attr_accessor :dont_remove_source_code
            dont_remove_source_code = false

            class_attr_accessor :custom_build_options
            class_attr_accessor :custom_build_options_simulator
            self.custom_build_options = []
            self.custom_build_options_simulator = []

            private
            class_attr_accessor :enable_prebuild_dev_pod
            self.enable_prebuild_dev_pod = false

            private
            class_attr_accessor :unbuilt_dev_pods
            self.unbuilt_dev_pods = Set[]

            private
            class_attr_accessor :unbuilt_vendor_pods
            self.unbuilt_vendor_pods = Set[]

            private
            class_attr_accessor :unbuilt_pods
            self.unbuilt_pods = Set[]

            private
            class_attr_accessor :is_prebuild_job
            self.is_prebuild_job = false
        end
    end
end

Pod::HooksManager.register('cocoapods-binary-cache', :pre_install) do |installer_context|

    require_relative 'helper/feature_switches'
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
    require_relative 'helper/prebuild_sandbox'
    require_relative 'Prebuild'
    
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
    manifest_path = prebuild_sandbox.root + 'Manifest.lock'
    prebuilt_lockfile = Pod::Lockfile.from_file Pathname.new(manifest_path)
    missed_vendor_pods = PodCacheValidator.verify_prebuilt_vendor_pods(lockfile, prebuilt_lockfile)
    if !Pod::Podfile::DSL.is_prebuild_job
        Pod::Podfile::DSL.add_unbuilt_pods(missed_vendor_pods)
    end

    # Verify Dev pod cache
    if Pod::Podfile::DSL.enable_prebuild_dev_pod
        BenchmarkShow.benchmark { PodCacheValidator.verify_devpod_checksum(prebuild_sandbox, lockfile) }
        if !Pod::Podfile::DSL.is_prebuild_job
            Pod::Podfile::DSL.add_unbuilt_pods(Pod::Prebuild::CacheInfo.cache_miss_local_pods)
        end
    end

    binary_installer.clean_delta_file
    Pod::UI.puts "Pod update = #{update}"
    if binary_installer.have_exact_prebuild_cache? && !update
        Pod::UI.puts "cache hit"
        binary_installer.install_when_cache_hit!
    else
        Pod::UI.puts "cache miss -> need to update"
        binary_installer.update = update
        binary_installer.repo_update = repo_update
        binary_installer.install!
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
    require_relative 'Integration'
    # go on the normal install step ...
end

Pod::HooksManager.register('cocoapods-binary-cache', :post_install) do |installer_context|
    next unless Pod::Podfile::DSL.enable_prebuild_dev_pod and installer_context.sandbox.instance_of?(Pod::PrebuildSandbox)

    # Modify pods scheme to support code coverage
    # If we don't prebuild dev pod -> no need to care about this in Pod project because we setup in the main project. Eg. DriverCI scheme
    if Pod.is_prebuild_stage
        require 'rexml/document'
        pod_proj_path = installer_context.sandbox.project_path
        puts "Modify schemes of pod project to support code coverage of prebuilt local pod: #{pod_proj_path}"
        scheme_files = Dir["#{pod_proj_path}/**/*.xcscheme"]
        scheme_files.each do |file_path|
            scheme_name = File.basename(file_path, '.*')
            next unless installer_context.sandbox.local?(scheme_name)

            puts "Modify scheme to enable coverage symbol when prebuild: #{scheme_name}"
    
            doc = File.open(file_path, 'r') { |f| REXML::Document.new(f) }
            scheme = doc.elements['Scheme']
            test_action = scheme.elements['TestAction']
            next if test_action.attributes['codeCoverageEnabled'] == 'YES'

            test_action.add_attribute('codeCoverageEnabled', 'YES')
            test_action.add_attribute('onlyGenerateCoverageForSpecifiedTargets', 'YES')
            coverage_targets = REXML::Element.new('CodeCoverageTargets')
            buildable_ref = scheme.elements['BuildAction'].elements['BuildActionEntries'].elements['BuildActionEntry'].elements['BuildableReference']
            new_buildable_ref = buildable_ref.clone # Need to clone, otherwise the original one will be move to new place
            coverage_targets.add_element(new_buildable_ref)
            test_action.add_element(coverage_targets)
            File.open(file_path, 'w') { |f| doc.write(f) }
        end
    end
end