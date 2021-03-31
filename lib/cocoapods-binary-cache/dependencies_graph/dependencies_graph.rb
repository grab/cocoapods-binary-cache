# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

require "rgl/adjacency"
require "rgl/dot"
require_relative "graph_visualizer"

# Using RGL graph because GraphViz doesn't store adjacent of a node/vertex
# but we need to traverse a substree from any node
# https://github.com/monora/rgl/blob/master/lib/rgl/adjacency.rb

class DependenciesGraph
  def initialize(options)
    @lockfile = options[:lockfile]
    @devpod_only = options[:devpod_only]
    @max_deps = options[:max_deps].to_i if options[:max_deps]
    # A normal edge is an edge (one direction) from library A to library B which is a dependency of A.
    @invert_edge = options[:invert_edge] || false
  end

  # Input : a list of library names.
  # Output: a set of library names which are clients (directly and indirectly) of those input libraries.
  def get_clients(libnames)
    result = Set.new
    libnames.each do |lib|
      if graph.has_vertex?(lib)
        result.merge(traverse_sub_tree(graph, lib))
      else
        Pod::UI.puts "Warning: cannot find lib: #{lib}"
      end
    end
    result
  end

  def write_graphic_file(options)
    graph.write_to_graphic_file(options)
  end

  private

  def dependencies
    @dependencies ||= (@lockfile && @lockfile.to_hash["PODS"])
  end

  def dev_pod_sources
    @dev_pod_sources ||= @lockfile.to_hash["EXTERNAL SOURCES"].select { |_, attributes| attributes.key?(:path) } || {}
  end

  # Convert array of dictionaries -> a dictionary with format {A: [A's dependencies]}
  def pod_to_dependencies
    dependencies
      .map { |d| d.is_a?(Hash) ? d : { d => [] } }
      .reduce({}) { |combined, individual| combined.merge!(individual) }
  end

  def add_vertex(graph, pod)
    node_name = sanitized_pod_name(pod)
    return if @devpod_only && dev_pod_sources[node_name].nil?

    graph.add_vertex(node_name)
    node_name
  end

  def sanitized_pod_name(name)
    Pod::Dependency.from_string(name).name
  end

  def reach_max_deps(deps)
    return unless @max_deps
    return deps.count > @max_deps unless @devpod_only

    deps = deps.reject { |name| dev_pod_sources[name].nil? }
    deps.count > @max_deps
  end

  def graph
    @graph ||= begin
      graph = RGL::DirectedAdjacencyGraph.new
      pod_to_dependencies.each do |pod, dependencies|
        next if reach_max_deps(dependencies)

        pod_node = add_vertex(graph, pod)
        next if pod_node.nil?

        dependencies.each do |dependency|
          dep_node = add_vertex(graph, dependency)
          next if dep_node.nil?

          if @invert_edge
            graph.add_edge(dep_node, pod_node)
          else
            graph.add_edge(pod_node, dep_node)
          end
        end
      end
      graph
    end
  end

  def traverse_sub_tree(graph, vertex)
    visited_nodes = Set.new
    graph.each_adjacent(vertex) do |v|
      visited_nodes.add(v)
      visited_nodes.merge(traverse_sub_tree(graph, v))
    end
    visited_nodes
  end
end
