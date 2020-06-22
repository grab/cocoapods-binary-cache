# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file
# https://github.com/monora/rgl/blob/0b526e16f9fb344abf387f4c5523d7917ce8f4b1/lib/rgl/dot.rb

require 'rgl/rdot'

module RGL
  module Graph
    def to_dot_graph(params={}, highlight_nodes)
      params['name'] ||= self.class.name.gsub(/:/, '_')
      fontsize       = params['fontsize'] ? params['fontsize'] : '12'
      graph          = (directed? ? DOT::Digraph : DOT::Graph).new(params)
      edge_class     = directed? ? DOT::DirectedEdge : DOT::Edge
      vertex_options = params['vertex'] || {}
      edge_options   = params['edge'] || {}

      each_vertex do |v|
        default_vertex_options =  {
          'name'     => vertex_id(v),
          'fontsize' => fontsize,
          'label'    => vertex_label(v),
          'style'    => 'filled',
        }
        if highlight_nodes.include?(v)
          default_vertex_options = default_vertex_options.merge({
            'color' => 'red',
            'fillcolor' => 'red'
          })
        else
          default_vertex_options = default_vertex_options.merge({
            'color' => 'blue',
            'fillcolor' => 'blue'
          })
        end

        each_vertex_options = default_vertex_options.merge(vertex_options)
        vertex_options.each{|option, val| each_vertex_options[option] = val.call(v) if val.is_a?(Proc)}
        graph << DOT::Node.new(each_vertex_options)
      end

      each_edge do |u, v|
        default_edge_options = {
          'from'     => vertex_id(u),
          'to'       => vertex_id(v),
          'fontsize' => fontsize
        }
        each_edge_options = default_edge_options.merge(edge_options)
        edge_options.each{|option, val| each_edge_options[option] = val.call(u, v) if val.is_a?(Proc)}
        graph << edge_class.new(each_edge_options)
      end

      graph
    end

    def write_to_graphic_file(fmt='png', dotfile="graph", options={}, highlight_nodes)
      src = dotfile + ".dot"
      dot = dotfile + "." + fmt

      File.open(src, 'w') do |f|
        f << self.to_dot_graph(params=options, highlight_nodes=highlight_nodes).to_s << "\n"
      end

      unless system("dot -T#{fmt} #{src} -o #{dot}")
        message = <<-HEREDOC # Use <<- to indent End of String terminator
          Error executing dot. Did you install GraphViz?
          Try installing it via Homebrew: `brew install graphviz`.
          Visit https://graphviz.org/download/ for more installation instructions.
        HEREDOC
        raise message
      end
      dot
    end
  end
end
