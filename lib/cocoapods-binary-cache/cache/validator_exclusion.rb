module PodPrebuild
  class ExclusionCacheValidator < AccumulatedCacheValidator
    def initialize(options)
      super(options)
      @ignored_pods = options[:ignored_pods] || Set.new
      @prebuilt_pod_names = options[:prebuilt_pod_names]
    end

    def validate(accumulated)
      validation = @prebuilt_pod_names.nil? ? accumulated : accumulated.keep(@prebuilt_pod_names)
      validation.discard(@ignored_pods)
    end
  end
end
