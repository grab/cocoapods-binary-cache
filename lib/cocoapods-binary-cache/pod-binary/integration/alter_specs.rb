module Pod
  class Installer
    def alter_specs_for_prebuilt_pods
      cache = []

      @original_specs = analysis_result.specifications
        .map { |spec| [spec.name, Pod::Specification.from_file(spec.defined_in_file)] }
        .to_h

      analysis_result.specifications
        .select { |spec| should_integrate_prebuilt_pod?(spec.root.name) }
        .group_by(&:root)
        .each do |_, specs|
          first_subspec_or_self = specs.find(&:subspec?) || specs[0]
          specs.each do |spec|
            alterations = {
              :source_files => true,
              :resources => true,
              :license => true,
              :vendored_framework => spec == first_subspec_or_self
            }
            alter_spec(spec, alterations, cache)
          end
        end
    end

    private

    def metadata_of_target(name)
      @metadata_by_target ||= {}
      metadata = @metadata_by_target[name]
      return metadata unless metadata.nil?

      framework_path = sandbox.prebuild_sandbox.framework_folder_path_for_target_name(name)
      metadata = PodPrebuild::Metadata.in_dir(framework_path)
      @metadata_by_target[name] = metadata
      metadata
    end

    def alter_spec(spec, alterations, cache)
      metadata = metadata_of_target(spec.root.name)
      targets = Pod.fast_get_targets_for_pod_name(spec.root.name, pod_targets, cache)
      platforms = targets.map { |target| target.platform.name.to_s }.uniq

      if alterations[:vendored_framework]
        targets.each do |target|
          # Use the prebuilt frameworks as vendered frameworks.
          # The framework_file_path rule is decided in `install_for_prebuild`,
          # as to compitable with older version and be less wordy.
          framework_file_path = target.framework_name
          framework_file_path = target.name + "/" + framework_file_path if targets.count > 1
          framework_file_path = PodPrebuild.config.prebuilt_path(path: framework_file_path)
          add_vendered_framework(spec, target.platform.name.to_s, framework_file_path)
        end
      end

      empty_source_files(spec, platforms) if alterations[:source_files]
      if alterations[:resources]
        if metadata.static_framework?
          tweak_resources_for_xib(spec, platforms)
          tweak_resources_for_resource_bundles(spec, platforms)
        else
          # For dynamic frameworks, resources & resource bundles are already bundled inside the framework.
          # We need to empty resources & resource bundles. Otherwise, there will be duplications
          # (resources locating in both app bundle and framework bundle)
          empty_resources(spec, platforms)
        end
      end
      empty_liscence(spec) if alterations[:license]
    end

    def empty_resources(spec, platforms)
      spec.attributes_hash["resources"] = nil
      spec.attributes_hash["resource_bundles"] = nil
      platforms.each do |platform|
        next if spec.attributes_hash[platform].nil?

        spec.attributes_hash[platform]["resources"] = nil
        spec.attributes_hash[platform]["resource_bundles"] = nil
      end
    end

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
        attributes["resources"] += resource_bundle_names.map do |name|
          PodPrebuild.config.prebuilt_path(path: "#{name}.bundle")
        end
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

    def empty_source_files(spec, platforms)
      spec.attributes_hash["source_files"] = []
      platforms.each do |platform|
        spec.attributes_hash[platform]["source_files"] = [] unless spec.attributes_hash[platform].nil?
      end
    end

    def empty_liscence(spec)
      spec.attributes_hash["license"] = {}
      spec.root.attributes_hash["license"] = {}
    end
  end
end
