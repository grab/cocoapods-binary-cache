module Pod
  class Installer
    # Returns the names of pod targets detected as prebuilt, including
    # those declared in Podfile and their dependencies
    def prebuilt_pod_names
      prebuilt_pod_targets.map(&:name).to_set
    end

    # Returns the pod targets detected as prebuilt, including
    # those declared in Podfile and their dependencies
    def prebuilt_pod_targets
      @prebuilt_pod_targets ||= begin
        explicit_prebuilt_pod_names = aggregate_targets
          .flat_map { |target| target.target_definition.explicit_prebuilt_pod_names }
          .uniq

        targets = pod_targets.select { |target| explicit_prebuilt_pod_names.include?(target.pod_name) }
        dependencies = targets.flat_map(&:recursive_dependent_targets) # Treat dependencies as prebuilt pods
        all = (targets + dependencies).uniq
        all = all.reject { |target| sandbox.local?(target.pod_name) } unless PodPrebuild.config.dev_pods_enabled?
        all
      end
    end
  end
end
