module PodPrebuild
  class StateStore
    @cache_validation = CacheValidationResult.new
    class << self
      attr_accessor :cache_validation
    end
  end
end
