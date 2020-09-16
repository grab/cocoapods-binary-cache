require_relative "executor/fetcher"

module Pod
  class Command
    class Binary < Command
      class Fetch < Binary
        self.arguments = [CLAide::Argument.new("CACHE-BRANCH", false)]
        def initialize(argv)
          super
          @fetcher = PodPrebuild::CacheFetcher.new(
            config: prebuild_config,
            cache_branch: argv.shift_argument || "master"
          )
        end

        def run
          @fetcher.run
        end
      end
    end
  end
end
