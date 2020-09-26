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
      output_path = "#{@output_dir}/graph.png"
      graph.write_graphic_file(output_path: output_path)
      system("open #{@output_path}") if @open
    end
  end
end
