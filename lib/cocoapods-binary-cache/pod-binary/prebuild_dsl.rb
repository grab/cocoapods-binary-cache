require_relative "tool/tool"
require_relative "../prebuild_config"

module Pod
  class Podfile
    module DSL
      def config_cocoapods_binary_cache(options)
        apply_config = lambda do |config|
          DSL.send("#{config}=", options[config]) unless options[config].nil?
        end

        PrebuildConfig.CONFIGURATION = options[:prebuild_config] || "Debug"
        apply_config.call(:prebuild_job)
        apply_config.call(:prebuild_all) # TODO (thuyen): Revise this option
        apply_config.call(:prebuild_all_vendor_pods)
        apply_config.call(:excluded_pods)
        apply_config.call(:dev_pods_enabled)
        apply_config.call(:bitcode_enabled)
        apply_config.call(:dont_remove_source_code)
        apply_config.call(:custom_device_build_options)
        apply_config.call(:custom_simulator_build_options)
        apply_config.call(:save_cache_validation_to)
        apply_config.call(:validate_prebuilt_settings)
      end

      @prebuild_job = false
      @prebuild_all = false
      @prebuild_all_vendor_pods = false
      @excluded_pods = Set.new
      @dev_pods_enabled = false
      @bitcode_enabled = false
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

      class << self
        attr_accessor :prebuild_job
        attr_accessor :prebuild_all
        attr_accessor :prebuild_all_vendor_pods
        attr_accessor :excluded_pods
        attr_accessor :dev_pods_enabled
        attr_accessor :bitcode_enabled
        attr_accessor :dont_remove_source_code
        attr_accessor :custom_device_build_options
        attr_accessor :custom_simulator_build_options
        attr_accessor :save_cache_validation_to
        attr_accessor :validate_prebuilt_settings
      end
    end
  end
end
