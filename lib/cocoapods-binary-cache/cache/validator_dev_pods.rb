module PodPrebuild
  class DevPodsCacheValidator < BaseCacheValidator
    def validate
      # TODO (thuyen): Migrate the code PodCacheValidator.verify_devpod_checksum to this place
      PodPrebuild::CacheValidationResult.new({}, Set.new)
    end
  end
end
