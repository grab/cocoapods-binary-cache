# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file
# https://github.com/monora/rgl/blob/0b526e16f9fb344abf387f4c5523d7917ce8f4b1/lib/rgl/dot.rb

require "rgl/rdot"

module RGL
  module Graph
    def to_dot_graph(options)
      highlight_nodes = options[:highlight_nodes] || Set.new
      options["name"] ||= self.class.name.gsub(/:/, "_")
      fontsize = options["fontsize"] || "12"
      graph = (directed? ? DOT::Digraph : DOT::Graph).new(options)
      edge_class = directed? ? DOT::DirectedEdge : DOT::Edge
      vertex_options = options["vertex"] || {}
      edge_options = options["edge"] || {}

      each_vertex do |v|
        default_vertex_options = {
          "name" => vertex_id(v),
          "fontsize" => fontsize,
          "label" => vertex_label(v),
          "style" => "filled"
        }
        default_vertex_options.merge!("color" => "red", "fillcolor" => "red") if highlight_nodes.include?(v)
        each_vertex_options = default_vertex_options.merge(vertex_options)
        vertex_options.each { |option, val| each_vertex_options[option] = val.call(v) if val.is_a?(Proc) }
        graph << DOT::Node.new(each_vertex_options)
      end

      each_edge do |u, v|
        default_edge_options = {
          "from" => vertex_id(u),
          "to" => vertex_id(v),
          "fontsize" => fontsize
        }
        each_edge_options = default_edge_options.merge(edge_options)
        edge_options.each { |option, val| each_edge_options[option] = val.call(u, v) if val.is_a?(Proc) }
        graph << edge_class.new(each_edge_options)
      end

      graph
    end

    def write_to_graphic_file(options)
      output_path = Pathname.new(options[:output_path])
      fmt = output_path.extname.delete_prefix(".")
      dotfile = output_path.sub_ext(".dot")

      File.open(dotfile, "w") do |f|
        f << to_dot_graph(options).to_s
      end

      unless system("dot -T#{fmt} #{dotfile} -o #{output_path}")
        message = <<~HEREDOC
          Error executing dot. Did you install GraphViz?
          Try installing it via Homebrew: `brew install graphviz`.
          Visit https://graphviz.org/download/ for more installation instructions.
        HEREDOC
        raise message
      end
      output_path
    end
  end
end
