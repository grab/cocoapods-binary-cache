module PodPrebuild
  class StateStore
    @excluded_pods = Set.new
    @cache_validation = CacheValidationResult.new

    class << self
      attr_accessor :excluded_pods
      attr_accessor :cache_validation
    end
  end
end
