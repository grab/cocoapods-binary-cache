module PodPrebuild
  class BaseDiagnosis
    def initialize(options)
      @cache_validation = options[:cache_validation]
      @standard_sandbox = options[:standard_sandbox]
      @specs = (options[:specs] || []).map { |s| [s.name, s] }.to_h
    end

    def spec(name)
      @specs[name]
    end
  end
end
