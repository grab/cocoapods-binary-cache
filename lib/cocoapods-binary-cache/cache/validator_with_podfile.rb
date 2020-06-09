module PodPrebuild
  class PodfileChangesCacheValidator < BaseCacheValidator
    def validate(*)
      validate_with_podfile
    end
  end
end
