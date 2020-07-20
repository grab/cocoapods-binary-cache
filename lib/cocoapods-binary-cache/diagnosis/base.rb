module PodPrebuild
  class BaseDiagnosis
    def initialize(options)
      @cache_validation = options[:cache_validation]
      @standard_sandbox = options[:standard_sandbox]
    end
  end
end
