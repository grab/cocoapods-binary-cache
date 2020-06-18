module Pod
  class Installer
    def validate_every_pod_only_have_one_form
      multi_targets_pods = pod_targets
        .group_by(&:pod_name)
        .select do |_, targets|
          is_multi_targets = targets.map { |t| t.platform.name }.uniq.count > 1
          is_multi_forms = targets.map { |t| prebuilt_pod_targets.include?(t) }.uniq.count > 1
          is_multi_targets && is_multi_forms
        end
      return if multi_targets_pods.empty?

      warnings = "One pod can only be prebuilt or not prebuilt. These pod have different forms in multiple targets:\n"
      warnings += multi_targets_pods
        .map { |name, targets| "         #{name}: #{targets.map { |t| t.platform.name }}" }
        .join("\n")
      raise Informative, warnings
    end
  end
end
