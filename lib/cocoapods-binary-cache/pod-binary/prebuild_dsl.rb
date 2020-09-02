require_relative "tool/tool"

module Pod
  class Podfile
    module DSL
      def config_cocoapods_binary_cache(options)
        apply_config = lambda do |config|
          DSL.send("#{config}=", options[config]) unless options[config].nil?
        end

        apply_config.call(:prebuild_config)
        apply_config.call(:prebuild_all) # TODO (thuyen): Revise this option
        apply_config.call(:prebuild_all_vendor_pods)
        apply_config.call(:excluded_pods)
        apply_config.call(:dev_pods_enabled)
        apply_config.call(:bitcode_enabled)
        apply_config.call(:device_build_enabled)
        apply_config.call(:dont_remove_source_code)
        apply_config.call(:custom_device_build_options)
        apply_config.call(:custom_simulator_build_options)
        apply_config.call(:save_cache_validation_to)
        apply_config.call(:validate_prebuilt_settings)
        apply_config.call(:prebuild_code_gen)
      end

      @prebuild_config = "Debug"
      @prebuild_job = false
      @prebuild_all = false
      @prebuild_all_vendor_pods = false
      @excluded_pods = Set.new
      @dev_pods_enabled = false
      @bitcode_enabled = false
      @device_build_enabled = false
      @dont_remove_source_code = false
      @custom_device_build_options = []
      @custom_simulator_build_options = []
      @save_cache_validation_to = nil
      # A proc to validate the provided build settings (per target) with the build settings of the prebuilt frameworks
      # For example, in Podfile:
      # -----------------------------------------------
      #   validate_prebuilt_settings do |target|
      #     settings = {}
      #     settings["MACH_O_TYPE"] == "staticlib"
      #     settings["SWIFT_VERSION"] == swift_version_of(target)
      #     settings
      #   end
      # -----------------------------------------------
      @validate_prebuilt_settings = nil
      @prebuild_code_gen = nil

      class << self
        attr_accessor :prebuild_config
        attr_accessor :prebuild_job
        attr_accessor :prebuild_all
        attr_accessor :prebuild_all_vendor_pods
        attr_accessor :excluded_pods
        attr_accessor :dev_pods_enabled
        attr_accessor :bitcode_enabled
        attr_accessor :device_build_enabled
        attr_accessor :dont_remove_source_code
        attr_accessor :custom_device_build_options
        attr_accessor :custom_simulator_build_options
        attr_accessor :save_cache_validation_to
        attr_accessor :validate_prebuilt_settings
        attr_accessor :prebuild_code_gen

        alias prebuild_job? prebuild_job
        alias prebuild_all? prebuild_all
        alias prebuild_all_vendor_pods? prebuild_all_vendor_pods
        alias dev_pods_enabled? dev_pods_enabled
      end
    end
  end
end
