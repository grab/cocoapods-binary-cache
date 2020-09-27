module Pod
  class Podfile
    module DSL
      def config_cocoapods_binary_cache(options)
        PodPrebuild.config.dsl_config = options
        PodPrebuild.config.validate_dsl_config
      end
    end
  end
end
