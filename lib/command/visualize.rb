require_relative "executor/visualizer"

module Pod
  class Command
    class Binary < Command
      class Viz < Binary
        self.arguments = [CLAide::Argument.new("OUTPUT-DIR", false)]
        def self.options
          [
            ["--open", "Open the graph upon completion"]
          ]
        end

        def initialize(argv)
          super
          @visualizer = PodPrebuild::Visualizer.new(
            config: prebuild_config,
            lockfile: config.lockfile,
            output_dir: argv.shift_argument || ".",
            open: argv.flag?("open")
          )
        end

        def run
          @visualizer.run
        end
      end
    end
  end
end
