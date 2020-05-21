require "fileutils"
require_relative "../pod-rome/build_framework"
require_relative "../prebuild_output/output"
require_relative "helper/passer"
require_relative "helper/target_checker"

# patch prebuild ability
module Pod
  class Installer
    private

    def local_manifest
      unless @local_manifest_inited
        @local_manifest_inited = true
        raise "This method should be call before generate project" unless analysis_result.nil?

        @local_manifest = sandbox.manifest
      end
      @local_manifest
    end

    # @return [Analyzer::SpecsState]
    def prebuild_pods_changes
      return nil if local_manifest.nil?

      if @prebuild_pods_changes.nil?
        changes = local_manifest.detect_changes_with_podfile(podfile)
        @prebuild_pods_changes = Analyzer::SpecsState.new(changes)
        # save the chagnes info for later stage
        Pod::Prebuild::Passer.prebuild_pods_changes = @prebuild_pods_changes
      end
      @prebuild_pods_changes
    end

    def blacklisted?(name)
      Pod::Podfile::DSL.unbuilt_pods.include?(name)
    end

    def cache_hit?(name)
      Prebuild::CacheInfo.cache_hit_vendor_pods.include?(name) ||
        Prebuild::CacheInfo.cache_hit_dev_pods_dic.include?(name)
    end

    def should_not_prebuild_vendor_pod(name)
      return true if blacklisted?(name)
      return false if Pod::Podfile::DSL.prebuild_all_vendor_pods

      cache_hit?(name)
    end

    public

    def prebuild_output
      @prebuild_output ||= PodPrebuild::Output.new(sandbox)
    end

    def cache_miss
      return Set.new if local_manifest.nil?

      changes = prebuild_pods_changes
      added = changes.added
      changed = changes.changed
      unchanged = changes.unchanged
      deleted = changes.deleted

      exsited_framework_pod_names = sandbox.exsited_framework_pod_names
      missing = unchanged.reject { |pod_name| exsited_framework_pod_names.include?(pod_name) }

      UI.puts "Added frameworks: #{added.to_a}"
      UI.puts "Changed frameworks: #{changed.to_a}"
      UI.puts "Deleted frameworks: #{deleted.to_a}"
      UI.puts "Missing frameworks: #{missing.to_a}"
      needed = (added + changed + missing)
      if Pod::Podfile::DSL.enable_prebuild_dev_pod && Pod::Podfile::DSL.is_prebuild_job
        needed += Pod::Prebuild::CacheInfo.cache_miss_dev_pods_dic.keys
      end
      needed = needed.reject { |name| blacklisted?(name) || cache_hit?(name) }
      UI.puts "Need to rebuild: #{needed.count} #{needed}"
      needed
    end

    # The install method when have completed cache
    def install_when_cache_hit!
      # just print log
      sandbox.exsited_framework_target_names.each do |name|
        UI.puts "Using #{name}"
      end
    end

    # Build the needed framework files
    def prebuild_frameworks!
      UI.puts "Start prebuild_frameworks"

      # build options
      sandbox_path = sandbox.root
      existed_framework_folder = sandbox.generate_framework_path
      bitcode_enabled = Pod::Podfile::DSL.bitcode_enabled
      targets = []

      if Pod::Podfile::DSL.prebuild_all_vendor_pods
        UI.puts "Rebuild all vendor frameworks"
        targets = pod_targets
      elsif !local_manifest.nil?
        UI.puts "Update some frameworks"
        changes = prebuild_pods_changes
        added = changes.added
        changed = changes.changed
        unchanged = changes.unchanged

        existed_framework_folder.mkdir unless existed_framework_folder.exist?
        exsited_framework_pod_names = sandbox.exsited_framework_pod_names

        # additions
        missing = unchanged.reject { |pod_name| exsited_framework_pod_names.include?(pod_name) }

        root_names_to_update = (added + changed + missing)
        if Pod::Podfile::DSL.enable_prebuild_dev_pod && Pod::Podfile::DSL.is_prebuild_job
          root_names_to_update += Pod::Prebuild::CacheInfo.cache_miss_dev_pods_dic.keys
        end

        # transform names to targets
        cache = []
        targets = root_names_to_update.map do |pod_name|
          tars = Pod.fast_get_targets_for_pod_name(pod_name, pod_targets, cache)
          if tars.nil? || tars.empty?
            raise "There's no target named (#{pod_name}) in Pod.xcodeproj.\n #{pod_targets.map(&:name)}" if t.nil?
          end
          tars
        end.flatten

        # add the dendencies
        dependency_targets = targets.map(&:recursive_dependent_targets).flatten.uniq || []
        targets = (targets + dependency_targets).uniq
      else
        UI.puts "Rebuild all frameworks"
        targets = pod_targets
      end

      targets = targets.reject { |pod_target| should_not_prebuild_vendor_pod(pod_target.name) }
      unless Podfile::DSL.enable_prebuild_dev_pod
        targets = targets.reject { |pod_target| sandbox.local?(pod_target.pod_name) }
      end

      # build!
      Pod::UI.puts "Prebuild frameworks (total #{targets.count})"
      Pod::UI.puts targets.map(&:name)

      Pod::Prebuild.remove_build_dir(sandbox_path)
      targets.each do |target|
        unless target.should_build?
          Pod::UI.puts "Skip prebuilding #{target.label} because of no source files".yellow
          next
          # TODO (thuyen): Fix an issue in this scenario:
          # - Frameworks are shipped as vendor frameworks (-> skipped during prebuild)
          # -> The dir structure of this framework in Pods is incorrect.
          #    - Expected: Pods/MyFramework/<my_files>
          #    - Actual: Pods/MyFramework/MyFramework/<my_files>. Sometimes, Pods/MyFramework is empty :|
          # -> Better to detect such targets EARLY and add them to the blacklist (DSL.unbuilt_pods)
        end

        output_path = sandbox.framework_folder_path_for_target_name(target.name)
        output_path.mkpath unless output_path.exist?
        Pod::Prebuild.build(
          sandbox_path,
          target,
          output_path,
          bitcode_enabled,
          Podfile::DSL.custom_build_options,
          Podfile::DSL.custom_build_options_simulator
        )
        collect_metadata(target, output_path)
      end
      Pod::Prebuild.remove_build_dir(sandbox_path)

      # copy vendored libraries and frameworks
      targets.each do |target|
        root_path = sandbox.pod_dir(target.name)
        target_folder = sandbox.framework_folder_path_for_target_name(target.name)

        # If target shouldn't build, we copy all the original files
        # This is for target with only .a and .h files
        unless target.should_build?
          Prebuild::Passer.target_names_to_skip_integration_framework << target.name
          FileUtils.cp_r(root_path, target_folder, :remove_destination => true)
          next
        end

        target.spec_consumers.each do |consumer|
          file_accessor = Sandbox::FileAccessor.new(root_path, consumer)
          lib_paths = file_accessor.vendored_frameworks || []
          lib_paths += file_accessor.vendored_libraries
          # @TODO dSYM files
          lib_paths.each do |lib_path|
            relative = lib_path.relative_path_from(root_path)
            destination = target_folder + relative
            destination.dirname.mkpath unless destination.dirname.exist?
            FileUtils.cp_r(lib_path, destination, :remove_destination => true)
          end
        end
      end

      # save the pod_name for prebuild framwork in sandbox
      targets.each do |target|
        sandbox.save_pod_name_for_target target
      end

      # Remove useless files
      # remove useless pods
      all_needed_names = pod_targets.map(&:name).uniq
      useless_target_names = sandbox.exsited_framework_target_names.reject do |name|
        all_needed_names.include? name
      end
      useless_target_names.each do |name|
        UI.puts "Remove: #{name}"
        path = sandbox.framework_folder_path_for_target_name(name)
        path.rmtree if path.exist?
      end

      if Podfile::DSL.dont_remove_source_code
        # just remove the tmp files
        path = sandbox.root + "Manifest.lock.tmp"
        path.rmtree if path.exist?
      else
        # only keep manifest.lock and framework folder in _Prebuild
        to_remain_files = ["Manifest.lock", File.basename(existed_framework_folder)]
        to_delete_files = sandbox_path.children.reject { |file| to_remain_files.include?(File.basename(file)) }
        to_delete_files.each { |file| file.rmtree if file.exist? }
      end

      updated_target_names = targets.map { |target| target.label.to_s }
      deleted_target_names = useless_target_names
      Pod::UI.puts "Targets to prebuild: #{updated_target_names}"
      Pod::UI.puts "Targets to cleanup: #{deleted_target_names}"

      prebuild_output.write_delta_file(updated_target_names, deleted_target_names)
      prebuild_output.process_prebuilt_dev_pods
    end

    def clean_delta_file
      prebuild_output.clean_delta_file
    end

    def collect_metadata(target, output_path)
      metadata = PodPrebuild::Metadata.in_dir(output_path)
      metadata.framework_name = target.framework_name
      metadata.static_framework = target.static_framework?
      resource_paths = target.resource_paths
      metadata.resources = resource_paths.is_a?(Hash) ? resource_paths.values.flatten : resource_paths
      metadata.resource_bundles = target
        .file_accessors
        .map { |f| f.resource_bundles.keys }
        .flatten
        .map { |name| "#{name}.bundle" }
      metadata.build_settings = pods_project.targets
        .detect { |native_target| native_target.name == target.name }
        .build_configurations
        .detect { |config| config.name == PrebuildConfig.CONFIGURATION }
        .build_settings
      metadata.save!
    end

    # patch the post install hook
    old_method2 = instance_method(:run_plugins_post_install_hooks)
    define_method(:run_plugins_post_install_hooks) do
      old_method2.bind(self).call
      prebuild_frameworks! if Pod.is_prebuild_stage && Pod::Podfile::DSL.is_prebuild_job
    end
  end
end
