module PodPrebuild
  class CacheValidationResult
    attr_reader :hit, :missed_with_reasons

    def initialize(missed_with_reasons = {}, hit = Set.new)
      @missed_with_reasons = missed_with_reasons
      @hit = hit - missed_with_reasons.keys
    end

    def missed
      @missed_with_reasons.keys.to_set
    end

    def missed?(name)
      @missed_with_reasons.key?(name)
    end

    def hit?(name)
      @hit.include?(name)
    end

    def merge(other)
      PodPrebuild::CacheValidationResult.new(
        @missed_with_reasons.merge(other.missed_with_reasons),
        @hit + other.hit
      )
    end

    def exclude_pods(names)
      should_exclude_pod = lambda do |pod_name|
        names.any? { |name| pod_name == name || pod_name.start_with?(name + "/") }
      end
      PodPrebuild::CacheValidationResult.new(
        @missed_with_reasons.reject { |pod_name, _| should_exclude_pod.call(pod_name) },
        @hit.reject { |pod_name| should_exclude_pod.call(pod_name) }.to_set
      )
    end

    def print_summary
      Pod::UI.puts "Cache validation: hit #{@hit.to_a}"
      @missed_with_reasons.each do |name, reason|
        Pod::UI.puts "Cache validation: missed #{name}. Reason: #{reason}".yellow
      end
    end
  end
end
