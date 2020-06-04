module PodPrebuild
  class CacheValidationResult
    attr_reader :hit, :missed_with_reasons

    def initialize(missed_with_reasons, hit)
      @missed_with_reasons = missed_with_reasons
      @hit = hit - missed_with_reasons.keys
    end

    def missed
      @missed_with_reasons.keys.to_set
    end

    def hit?(name)
      @hit.include(name)
    end

    def merge(other)
      PodPrebuild::CacheValidationResult.new(
        @missed_with_reasons.merge(other.missed_with_reasons),
        @hit + other.hit
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
