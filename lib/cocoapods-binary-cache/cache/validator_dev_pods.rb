module PodPrebuild
  class DevPodsCacheValidator < BaseCacheValidator
    def initialize(options)
      super(options)
      @sandbox_root = options[:sandbox_root]
    end

    def validate(*)
      return PodPrebuild::CacheValidationResult.new if @pod_lockfile.nil?

      # TODO (thuyen): Logic needs to be revised
      # TODO (thuyen): Migrate the code PodCacheValidator.verify_devpod_checksum to this place
      missed_with_checksum, hit_with_checksum = PodCacheValidator.verify_devpod_checksum(
        @sandbox_root,
        @generated_framework_path,
        @pod_lockfile.lockfile
      )
      missed = missed_with_checksum.transform_values { |checksum| "Checksum changed: #{checksum}" }
      PodPrebuild::CacheValidationResult.new(missed, hit_with_checksum.keys.to_set)
    end
  end
end
