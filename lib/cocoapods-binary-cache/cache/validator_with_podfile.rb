module PodPrebuild
  class PodfileChangesCacheValidator < BaseCacheValidator
    def validate(*)
      return PodPrebuild::CacheValidationResult.new if @prebuilt_lockfile.nil? || @podfile.nil?

      validate_with_podfile
    end
  end
end
