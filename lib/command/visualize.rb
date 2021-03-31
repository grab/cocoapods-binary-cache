require_relative "executor/visualizer"

module Pod
  class Command
    class Binary < Command
      class Viz < Binary
        self.arguments = [CLAide::Argument.new("OUTPUT-DIR", false)]
        def self.options
          [
            ["--open", "Open the graph upon completion"],
            ["--devpod_only", "Only include development pod"],
            ["--max_deps", "Only include pod with number of dependencies <= max_deps"]
          ]
        end

        def initialize(argv)
          super
          @visualizer = PodPrebuild::Visualizer.new(
            config: prebuild_config,
            lockfile: config.lockfile,
            output_dir: argv.shift_argument || ".",
            open: argv.flag?("open"),
            devpod_only: argv.flag?("devpod_only"),
            max_deps: argv.option("max_deps")
          )
        end

        def run
          @visualizer.run
        end
      end
    end
  end
end
