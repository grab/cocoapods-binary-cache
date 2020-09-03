require_relative "tool/tool"

module Pod
  class Podfile
    module DSL
      @binary_cache_config = {}
      @binary_cache_cli_config = {}
      def config_cocoapods_binary_cache(options)
        Pod::Podfile::DSL.binary_cache_config = options
      end

      class << self
        attr_accessor :binary_cache_config
        attr_accessor :binary_cache_cli_config

        def prebuild_config
          @binary_cache_config[:prebuild_config] || "Debug"
        end

        def prebuild_job?
          @binary_cache_cli_config[:prebuild_job] || @binary_cache_config[:prebuild_job]
        end

        def prebuild_all_pods?
          @binary_cache_cli_config[:prebuild_all_pods] || @binary_cache_config[:prebuild_all_pods]
        end

        def excluded_pods
          @binary_cache_config[:excluded_pods] || Set.new
        end

        def dev_pods_enabled?
          @binary_cache_config[:dev_pods_enabled]
        end

        def bitcode_enabled?
          @binary_cache_config[:bitcode_enabled]
        end

        def device_build_enabled?
          @binary_cache_config[:device_build_enabled]
        end

        def dont_remove_source_code?
          @binary_cache_config[:dont_remove_source_code]
        end

        def custom_device_build_options
          @binary_cache_config[:custom_device_build_options] || []
        end

        def custom_simulator_build_options
          @binary_cache_config[:custom_simulator_build_options] || []
        end

        def save_cache_validation_to
          @binary_cache_config[:save_cache_validation_to]
        end

        def validate_prebuilt_settings
          @binary_cache_config[:validate_prebuilt_settings]
        end

        def prebuild_code_gen
          @binary_cache_config[:prebuild_code_gen]
        end
      end
    end
  end
end
