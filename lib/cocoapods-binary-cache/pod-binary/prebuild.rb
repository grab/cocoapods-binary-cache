require "fileutils"
require_relative "../prebuild_output/output"
require_relative "../helper/lockfile"
require_relative "helper/passer"
require_relative "helper/target_checker"
require_relative "helper/build"

module Pod
  class PrebuildInstaller < Installer # rubocop:disable Metrics/ClassLength
    attr_reader :lockfile_wrapper

    def initialize(options)
      super(options[:sandbox], options[:podfile], options[:lockfile])
      @cache_validation = options[:cache_validation]
      @lockfile_wrapper = lockfile && PodPrebuild::Lockfile.new(lockfile)
    end

    private

    def local_manifest
      @local_manifest ||= sandbox.manifest
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
      PodPrebuild.config.excluded_pods.include?(name)
    end

    def cache_missed?(name)
      @cache_validation.missed?(name)
    end

    def should_not_prebuild_vendor_pod(name)
      return true if blacklisted?(name)
      return false if PodPrebuild.config.prebuild_all_pods?
    end

    def run_code_gen!(targets)
      return if PodPrebuild.config.prebuild_code_gen.nil?

      Pod::UI.title("Running code generation...") do
        PodPrebuild.config.prebuild_code_gen.call(self, targets)
      end
    end

    def targets_to_prebuild
      existed_framework_folder = sandbox.generate_framework_path
      targets = pod_targets

      targets_from_cli = PodPrebuild.config.targets_to_prebuild_from_cli
      if !targets_from_cli.empty?
        targets = targets.select { |target| targets_from_cli.include?(target.name) }
      elsif !PodPrebuild.config.prebuild_all_pods? && !local_manifest.nil?
        changes = prebuild_pods_changes
        added = changes.added
        changed = changes.changed
        unchanged = changes.unchanged

        existed_framework_folder.mkdir unless existed_framework_folder.exist?
        exsited_framework_pod_names = sandbox.exsited_framework_pod_names

        # additions
        missing = unchanged.reject { |pod_name| exsited_framework_pod_names.include?(pod_name) }

        root_names_to_update = (added + changed + missing)
        root_names_to_update += PodPrebuild.state.cache_validation.missed

        # transform names to targets
        cache = []
        targets = root_names_to_update.map do |pod_name|
          tars = Pod.fast_get_targets_for_pod_name(pod_name, pod_targets, cache) || []
          raise "There's no target named (#{pod_name}) in Pod.xcodeproj" if tars.empty?

          tars
        end.flatten

        # add the dendencies
        dependency_targets = targets.map(&:recursive_dependent_targets).flatten.uniq || []
        targets = (targets + dependency_targets).uniq
      end

      unless PodPrebuild.config.prebuild_all_pods?
        targets = targets.select { |pod_target| cache_missed?(pod_target.name) }
      end
      targets = targets.reject { |pod_target| should_not_prebuild_vendor_pod(pod_target.name) }
      unless PodPrebuild.config.dev_pods_enabled?
        targets = targets.reject { |pod_target| sandbox.local?(pod_target.pod_name) }
      end
      targets
    end

    public

    def prebuild_output
      @prebuild_output ||= PodPrebuild::Output.new(sandbox)
    end

    # Build the needed framework files
    def prebuild_frameworks!
      UI.puts "Start prebuild_frameworks"
      existed_framework_folder = sandbox.generate_framework_path
      sandbox_path = sandbox.root
      targets = targets_to_prebuild

      Pod::UI.puts "Prebuild frameworks (total #{targets.count}): #{targets.map(&:name)}"
      Pod::Prebuild.remove_build_dir(sandbox_path)
      run_code_gen!(targets)
      targets.each do |target|
        output_path = sandbox.framework_folder_path_for_target_name(target.name)
        output_path.mkpath unless output_path.exist?
        Pod::Prebuild.build(
          sandbox: sandbox_path,
          target: target,
          configuration: PodPrebuild.config.prebuild_config,
          output_path: output_path,
          bitcode_enabled: PodPrebuild.config.bitcode_enabled?,
          device_build_enabled: PodPrebuild.config.device_build_enabled?,
          disable_dsym: PodPrebuild.config.disable_dsym?,
          args: PodPrebuild.config.build_args
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

      if PodPrebuild.config.dont_remove_source_code?
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
        .detect { |config| config.name == PodPrebuild.config.prebuild_config }
        .build_settings
      metadata.source_hash = @lockfile_wrapper && @lockfile_wrapper.dev_pod_hash(target.name)

      # Store root path for code-coverage support later
      # TODO: update driver code-coverage logic to use path stored here
      project_root = PathUtils.remove_last_path_component(@sandbox.standard_sanbox_path.to_s)
      metadata.project_root = project_root
      metadata.save!
    end

    # patch the post install hook
    old_method2 = instance_method(:run_plugins_post_install_hooks)
    define_method(:run_plugins_post_install_hooks) do
      old_method2.bind(self).call
      prebuild_frameworks! if PodPrebuild::Env.prebuild_stage?
    end
  end
end
