require "fileutils"
require_relative "config"
require_relative "fetch"
require_relative "prebuild"
require_relative "visualize"

module Pod
  class Command
    class Binary < Command
      self.abstract_command = true
      self.default_subcommand = "fetch"

      def prebuild_config
        @prebuild_config ||= PodPrebuild::Config.new("PodBinaryCacheConfig.json")
      end
    end
  end
end
