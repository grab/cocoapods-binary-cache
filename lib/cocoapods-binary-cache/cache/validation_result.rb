module PodPrebuild
  class CacheValidationResult
    attr_reader :hit
    def initialize(missed, hit)
      @missed = missed
      @hit = hit
    end

    def missed
      @missed.keys.to_set
    end

    def print_summary
      Pod::UI.puts "Cache validation: hit #{@hit.to_a}"
      @missed.each do |name, reason|
        Pod::UI.puts "Cache validation: missed #{name}. Reason: #{reason}".yellow
      end
    end
  end
end
