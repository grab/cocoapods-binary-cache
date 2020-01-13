require_relative 'tool/tool'
require_relative '../prebuild_config'

module Pod
  class Podfile
    module DSL

      # Enable prebuiding for all pods
      # it has a lower priority to other binary settings
      def all_binary!
        DSL.prebuild_all = true
      end

      # Enable bitcode for prebuilt frameworks
      def enable_bitcode_for_prebuilt_frameworks!
        DSL.bitcode_enabled = true
      end

      # Don't remove source code of prebuilt pods
      # It may speed up the pod install if git didn't
      # include the `Pods` folder
      def keep_source_code_for_prebuilt_frameworks!
        DSL.dont_remove_source_code = true
      end

      # Add custom xcodebuild option to the prebuilding action
      #
      # You may use this for your special demands. For example: the default archs in dSYMs
      # of prebuilt frameworks is 'arm64 armv7 x86_64', and no 'i386' for 32bit simulator.
      # It may generate a warning when building for a 32bit simulator. You may add following
      # to your podfile
      #
      #  ` set_custom_xcodebuild_options_for_prebuilt_frameworks :simulator => "ARCHS=$(ARCHS_STANDARD)" `
      #
      # Another example to disable the generating of dSYM file:
      #
      #  ` set_custom_xcodebuild_options_for_prebuilt_frameworks "DEBUG_INFORMATION_FORMAT=dwarf"`
      #
      #
      # @param [String or Hash] options
      #
      #   If is a String, it will apply for device and simulator. Use it just like in the commandline.
      #   If is a Hash, it should be like this: { :device => "XXXXX", :simulator => "XXXXX" }
      #
      def set_custom_xcodebuild_options_for_prebuilt_frameworks(options)
        if options.kind_of? Hash
          DSL.custom_build_options = [options[:device]] unless options[:device].nil?
          DSL.custom_build_options_simulator = [options[:simulator]] unless options[:simulator].nil?
        elsif options.kind_of? String
          DSL.custom_build_options = [options]
          DSL.custom_build_options_simulator = [options]
        else
          raise "Wrong type."
        end
      end

      def enable_devpod_prebuild
        DSL.enable_prebuild_dev_pod = true
      end

      def set_unbuilt_dev_pods(list)
        DSL.unbuilt_dev_pods = Set.new(list)
        DSL.unbuilt_pods = DSL.unbuilt_vendor_pods.merge(DSL.unbuilt_dev_pods)
      end

      def set_is_prebuild_job(flag)
        DSL.is_prebuild_job = flag
      end

      def set_unbuilt_vendor_pods(list)
        DSL.unbuilt_vendor_pods = Set.new(list)
        DSL.unbuilt_pods = DSL.unbuilt_vendor_pods.merge(DSL.unbuilt_dev_pods)
      end

      def set_prebuild_config(config)
        PrebuildConfig.CONFIGURATION = config # It's Debug by default
      end

      private

      def self.add_unbuilt_pods(list)
        DSL.unbuilt_pods = DSL.unbuilt_pods.merge(list)
      end

      private

      class_attr_accessor :prebuild_all
      prebuild_all = false

      class_attr_accessor :bitcode_enabled
      bitcode_enabled = false

      class_attr_accessor :dont_remove_source_code
      dont_remove_source_code = false

      class_attr_accessor :custom_build_options
      class_attr_accessor :custom_build_options_simulator
      self.custom_build_options = []
      self.custom_build_options_simulator = []

      private

      class_attr_accessor :enable_prebuild_dev_pod
      self.enable_prebuild_dev_pod = false

      private

      class_attr_accessor :unbuilt_dev_pods
      self.unbuilt_dev_pods = Set[]

      private

      class_attr_accessor :unbuilt_vendor_pods
      self.unbuilt_vendor_pods = Set[]

      private

      class_attr_accessor :unbuilt_pods
      self.unbuilt_pods = Set[]

      private

      class_attr_accessor :is_prebuild_job
      self.is_prebuild_job = false
    end
  end
end
