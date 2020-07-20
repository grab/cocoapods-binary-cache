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

      def prebuild_config
        @prebuild_config ||= PodPrebuild::Config.instance
      end
    end
  end
end
