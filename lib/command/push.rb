require_relative "executor/pusher"

module Pod
  class Command
    class Binary < Command
      class Push < Binary
        self.arguments = [CLAide::Argument.new("CACHE-BRANCH", false)]

        def initialize(argv)
          super
          @pusher = PodPrebuild::CachePusher.new(
            config: prebuild_config,
            cache_branch: argv.shift_argument || "master"
          )
        end

        def run
          @pusher.run
        end
      end
    end
  end
end
