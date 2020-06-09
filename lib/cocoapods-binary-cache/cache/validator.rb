module PodPrebuild
  class CacheValidator < BaseCacheValidator
    def initialize(options)
      super(options)
      @validators = [
        PodPrebuild::PodfileChangesCacheValidator.new(options),
        PodPrebuild::NonDevPodsCacheValidator.new(options)
      ]
      @validators << PodPrebuild::DevPodsCacheValidator.new(options) if Pod::Podfile::DSL.dev_pods_enabled
      @validators << PodPrebuild::DependenciesGraphCacheValidator.new(options)
    end

    def validate(*)
      validation = @validators.reduce(PodPrebuild::CacheValidationResult.new) do |acc, validator|
        acc.merge(validator.validate(acc))
      end
      validation.exclude_pods(@ignored_pods)
    end
  end
end
