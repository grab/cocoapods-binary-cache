require_relative "executor/prebuilder"

module Pod
  class Command
    class Binary < Command
      class Prebuild < Binary
        self.arguments = [CLAide::Argument.new("CACHE-BRANCH", false)]
        def self.options
          [
            ["--push", "Push cache to repo upon completion"]
          ]
        end

        def initialize(argv)
          super
          @prebuilder = PodPrebuild::CachePrebuilder.new(
            config: prebuild_config,
            cache_branch: argv.shift_argument || "master",
            push_cache: argv.flag?("push")
          )
        end

        def run
          @prebuilder.run
        end
      end
    end
  end
end
