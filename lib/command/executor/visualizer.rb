require_relative "base"
require_relative "../../cocoapods-binary-cache/dependencies_graph/dependencies_graph"

module PodPrebuild
  class Visualizer < CommandExecutor
    def initialize(options)
      super(options)
      @lockfile = options[:lockfile]
      @open = options[:open]
      @output_dir = options[:output_dir]
    end

    def run
      FileUtils.mkdir_p(@output_dir)
      graph = DependenciesGraph.new(@lockfile)
      graph.write_graphic_file("png", "#{@output_dir}/graph", Set.new)
      `open #{@output_dir}/graph.png` if @open
    end
  end
end
