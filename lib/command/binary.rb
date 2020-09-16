require "fileutils"
require_relative "config"
require_relative "fetch"
require_relative "prebuild"
require_relative "push"
require_relative "visualize"

module Pod
  class Command
    class Binary < Command
      self.abstract_command = true
      def self.options
        [
          ["--repo", "Cache repo (in accordance with `cache_repo` in `config_cocoapods_binary_cache`)"]
        ]
      end

      def initialize(argv)
        super
        load_podfile
        update_cli_config(:repo => argv.option("repo"))
      end

      def prebuild_config
        @prebuild_config ||= PodPrebuild.config
      end

      def load_podfile
        Pod::Config.instance.podfile
      end

      def update_cli_config(options)
        PodPrebuild.config.cli_config.merge!(options)
      end
    end
  end
end
