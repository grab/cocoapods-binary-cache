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

    def update_to(path)
      FileUtils.mkdir_p(File.dirname(path))
      json_file = PodPrebuild::JSONFile.new(path)
      json_file["cache_missed"] = missed.to_a
      json_file["cache_hit"] = hit.to_a
      json_file.save!
    end

    def exclude_pods(names)
      base_names = names.map { |name| name.split("/")[0] }.to_set
      should_exclude_pod = lambda do |pod_name|
        base_names.include?(pod_name.split("/")[0])
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
