module PodPrebuild
  class CacheValidator
    def initialize(options)
      @validators = [
        PodPrebuild::PodfileChangesCacheValidator.new(options),
        PodPrebuild::NonDevPodsCacheValidator.new(options)
      ]
      @validators << PodPrebuild::DevPodsCacheValidator.new(options) if PodPrebuild.config.dev_pods_enabled?
      @validators << PodPrebuild::DependenciesGraphCacheValidator.new(options)
      @validators << PodPrebuild::ExclusionCacheValidator.new(options)
    end

    def validate(*)
      @validators.reduce(PodPrebuild::CacheValidationResult.new) do |acc, validator|
        validation = validator.validate(acc)
        validator.is_a?(AccumulatedCacheValidator) ? validation : acc.merge(validation)
      end
    end
  end
end
