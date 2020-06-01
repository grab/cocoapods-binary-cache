module PodPrebuild
  class CacheValidator < BaseCacheValidator
    def initialize(options)
      super(options)
      @validators = [
        PodPrebuild::NonDevPodsCacheValidator.new(options),
        PodPrebuild::DevPodsCacheValidator.new(options)
      ]
    end

    def validate
      @validators.reduce(PodPrebuild::CacheValidationResult.new({}, Set.new)) do |acc, validator|
        acc.merge(validator.validate)
      end
    end
  end
end
