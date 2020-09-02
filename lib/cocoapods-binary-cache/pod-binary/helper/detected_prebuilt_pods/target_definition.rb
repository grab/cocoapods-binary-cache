module Pod
  class Podfile
    class TargetDefinition
      def detect_prebuilt_pod(name, requirements)
        @explicit_prebuilt_pod_names ||= []
        options = requirements.last || {}
        @explicit_prebuilt_pod_names << Specification.root_name(name) if options.is_a?(Hash) && options[:binary]
        options.delete(:binary) if options.is_a?(Hash)
        requirements.pop if options.empty?
      end

      # Returns the names of pod targets explicitly declared as prebuilt in Podfile using `:binary => true`.
      def explicit_prebuilt_pod_names
        names = @explicit_prebuilt_pod_names || []
        names += parent.explicit_prebuilt_pod_names if !parent.nil? && parent.is_a?(TargetDefinition)
        names
      end

      # ---- patch method ----
      # We want modify `store_pod` method, but it's hard to insert a line in the
      # implementation. So we patch a method called in `store_pod`.
      original_parse_inhibit_warnings = instance_method(:parse_inhibit_warnings)
      define_method(:parse_inhibit_warnings) do |name, requirements|
        detect_prebuilt_pod(name, requirements)
        original_parse_inhibit_warnings.bind(self).call(name, requirements)
      end
    end
  end
end
