# Let cocoapods use the prebuild framework files in install process.
#
# the code only effect the second pod install process.
#
module Pod
  class Installer
    # Remove the old target files if prebuild frameworks changed
    def remove_target_files_if_needed
      changes = Pod::Prebuild::Passer.prebuild_pods_changes
      updated_names = []
      if changes.nil?
        updated_names = PrebuildSandbox.from_standard_sandbox(sandbox).exsited_framework_pod_names
      else
        added = changes.added
        changed = changes.changed
        deleted = changes.deleted
        updated_names = added + changed + deleted
      end

      updated_names.each do |name|
        root_name = Specification.root_name(name)
        next if !Pod::Podfile::DSL.dev_pods_enabled && sandbox.local?(root_name)

        UI.puts "Delete cached files: #{root_name}"
        target_path = sandbox.pod_dir(root_name)
        target_path.rmtree if target_path.exist?

        support_path = sandbox.target_support_files_dir(root_name)
        support_path.rmtree if support_path.exist?
      end
    end

    # Modify specification to use only the prebuild framework after analyzing
    original_resolve_dependencies = instance_method(:resolve_dependencies)
    define_method(:resolve_dependencies) do
      # Remove the old target files. Otherwise, it will not notice file changes
      remove_target_files_if_needed
      original_resolve_dependencies.bind(self).call

      # check the pods
      # Although we have did it in prebuild stage, it's not sufficient.
      # Same pod may appear in another target in form of source code.
      # Prebuild.check_one_pod_should_have_only_one_target(prebuild_pod_targets)
      validate_every_pod_only_have_one_form

      # prepare
      cache = []

      def tweak_resources_for_xib(spec, platforms)
        # This is a workaround for prebuilt static framework that has `*.xib` files in the resources
        # (declared by `spec.resources = ...`)
        # ---------------------------------------------------------------
        # In the prebuild stage, a XIB file is compiled as a NIB file in the framework.
        # In the integration stage, this file is added to the script `Pods-<Target>-resources.sh`:
        #   - If it's a XIB, it's installed to the target bundle by `ibtool`
        #   - If it's a NIB, it's copied directly to the target bundle
        # Since the one embedded in the prebuilt framework is a NIB (already compiled)
        # --> We need to alter the spec so that this file will be copied to the target bundle
        change_xib_to_nib = ->(path) { path.sub(".xib", ".nib") }
        update_resources = lambda do |resources|
          if resources.is_a?(String)
            change_xib_to_nib.call(resources)
          elsif resources.is_a?(Array)
            resources.map { |item| change_xib_to_nib.call(item) }
          end
        end
        spec.attributes_hash["resources"] = update_resources.call(spec.attributes_hash["resources"])
        platforms.each do |platform|
          next if spec.attributes_hash[platform].nil?

          platform_resources = spec.attributes_hash[platform]["resources"]
          spec.attributes_hash[platform]["resources"] = update_resources.call(platform_resources)
        end
      end

      def tweak_resources_for_resource_bundles(spec, platforms)
        add_resource_bundles_to_resources = lambda do |attributes|
          return if attributes.nil?

          resource_bundles = attributes["resource_bundles"] || {}
          resource_bundle_names = resource_bundles.keys
          attributes["resource_bundles"] = nil
          attributes["resources"] ||= []
          attributes["resources"] = [attributes["resources"]] if attributes["resources"].is_a?(String)
          attributes["resources"] += resource_bundle_names.map { |n| n + ".bundle" }
        end

        add_resource_bundles_to_resources.call(spec.attributes_hash)
        platforms.each do |platform|
          add_resource_bundles_to_resources.call(spec.attributes_hash[platform])
        end
      end

      def add_vendered_framework(spec, platform, added_framework_file_path)
        spec.attributes_hash[platform] = {} if spec.attributes_hash[platform].nil?
        vendored_frameworks = spec.attributes_hash[platform]["vendored_frameworks"] || []
        vendored_frameworks = [vendored_frameworks] if vendored_frameworks.is_a?(String)
        vendored_frameworks += [added_framework_file_path]
        spec.attributes_hash[platform]["vendored_frameworks"] = vendored_frameworks
      end

      def empty_source_files(spec)
        spec.attributes_hash["source_files"] = []
        ["ios", "watchos", "tvos", "osx"].each do |platform|
          spec.attributes_hash[platform]["source_files"] = [] unless spec.attributes_hash[platform].nil?
        end
      end

      specs = analysis_result.specifications
      prebuilt_specs = specs.select { |spec| should_integrate_prebuilt_pod?(spec.root.name) }

      prebuilt_specs.each do |spec|
        # Use the prebuild framworks as vendered frameworks
        # get_corresponding_targets
        targets = Pod.fast_get_targets_for_pod_name(spec.root.name, pod_targets, cache)
        targets.each do |target|
          # the framework_file_path rule is decided when `install_for_prebuild`,
          # as to compitable with older version and be less wordy.
          framework_file_path = target.framework_name
          framework_file_path = target.name + "/" + framework_file_path if targets.count > 1
          add_vendered_framework(spec, target.platform.name.to_s, framework_file_path)
        end

        platforms = targets.map { |target| target.platform.name.to_s }
        tweak_resources_for_xib(spec, platforms)
        tweak_resources_for_resource_bundles(spec, platforms)

        # Clean the source files
        # we just add the prebuilt framework to specific platform and set no source files
        # for all platform, so it doesn't support the sence that 'a pod perbuild for one
        # platform and not for another platform.'
        empty_source_files(spec)

        # to avoid the warning of missing license
        spec.attributes_hash["license"] = {}
        spec.root.attributes_hash["license"] = {}
      end
    end

    # Override the download step to skip download and prepare file in target folder
    define_method(:install_source_of_pod) do |pod_name|
      pod_installer = create_pod_installer(pod_name)
      # Injected code
      # ------------------------------------------
      if should_integrate_prebuilt_pod?(pod_name)
        pod_installer.install_for_prebuild!(sandbox)
      else
        pod_installer.install!
      end
      # ------------------------------------------
      @installed_specs.concat(pod_installer.specs_by_platform.values.flatten.uniq)
    end

    def should_integrate_prebuilt_pod?(name)
      return false if !Pod::Podfile::DSL.prebuild_job && PodPrebuild::StateStore.cache_validation.missed?(name)

      prebuild_pod_names
        .reject { |pod| PodPrebuild::StateStore.excluded_pods.include?(pod) }
        .include?(name)
    end
  end
end
