module PodPrebuild
  class DevPodsCacheValidator < BaseCacheValidator
    def initialize(options)
      super(options)
      @sandbox_root = options[:sandbox_root]
    end

    def validate(*)
      return PodPrebuild::CacheValidationResult.new if @pod_lockfile.nil?

      hits = Set.new
      misses = {}
      @pod_lockfile.dev_pod_names.each do |name|
        diff = incompatible_source(name)
        if diff.empty?
          hits.add(name)
        else
          misses[name] = "Incompatible source: #{diff}"
        end
      end
      PodPrebuild::CacheValidationResult.new(misses, hits)
    end
  end
end
