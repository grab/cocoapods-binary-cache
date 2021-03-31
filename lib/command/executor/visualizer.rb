require_relative "base"
require_relative "../../cocoapods-binary-cache/dependencies_graph/dependencies_graph"

module PodPrebuild
  class Visualizer < CommandExecutor
    def initialize(options)
      super(options)
      @lockfile = options[:lockfile]
      @open = options[:open]
      @output_dir = options[:output_dir]
      @devpod_only = options[:devpod_only]
      @max_deps = options[:max_deps]
    end

    def run
      FileUtils.mkdir_p(@output_dir)
      graph = DependenciesGraph.new(lockfile: @lockfile, devpod_only: @devpod_only, max_deps: @max_deps)
      output_path = "#{@output_dir}/graph.png"
      graph.write_graphic_file(output_path: output_path)
      system("open #{@output_path}") if @open
    end
  end
end
