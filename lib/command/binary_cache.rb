# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

require 'fileutils'

module Pod
  class Command
    class BinaryCache < Command
      include Command::ProjectDirectory

      self.summary = 'Pod Binary Cache commands'

      self.description = <<-DESC
        Fetch/Prebuild pod frameworks
      DESC

      def self.options
        [
          ['--cmd', 'Commands to fetch, prebuild pod frameworks']
        ].concat(super)
      end

      def initialize(argv)
        @podspec_name = argv.shift_argument
        @cmd = argv.option("cmd", nil)
        @cache_branch = argv.option("cache_branch", nil)
        @push_vendor_pods = argv.option("push_vendor_pods", nil)
        Pod::UI.puts "BinaryCache run: #{@cmd}"
        super
      end

      def run
        if @cmd == 'deps_graph'
          require_relative '../cocoapods-binary-cache/dependencies_graph/dependencies_graph'
          dep_graph = DependenciesGraph.new(config.lockfile)
          fmt = 'png'
          name = 'graph'
          dep_graph.write_graphic_file(fmt, filename = name, highlight_nodes = Set[])
          system("open #{name}.#{fmt}")
          return
        end

        config_file_path = "#{config.installation_root}/PodBinaryCacheConfig.json"
        raise "#{config_file_path} not exist" unless File.exist?(config_file_path)

        py_cmd = []
        py_cmd << "python3" << "#{__dir__}/PythonScripts/prebuild_lib_cli.py"
        py_cmd << "--cmd #{@cmd}" << "--config_path #{config_file_path}"
        py_cmd << "--cache_branch #{@cache_branch}" unless @cache_branch.nil?
        py_cmd << "--push_vendor_pods #{@push_vendor_pods}" unless @push_vendor_pods.nil?
        cmd = py_cmd.join(" ")
        system(cmd) || (raise "Fail to run #{cmd}")
      end
    end
  end
end
