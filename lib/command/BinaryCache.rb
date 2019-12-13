require 'fileutils'

module Pod
  class Command
    class BinaryCache < Command
      include Command::ProjectDirectory

      self.summary = "Pod Binary Cache commands"

      self.description = <<-DESC
        Fetch/Prebuild pod frameworks
      DESC

      def self.options
        [
          ['--ignore-lockfile', 'Whether the lockfile should be ignored when calculating the dependency graph'],
          ['--cmd'],
          ['--filter-pattern', 'Filters out subtrees from pods with names matching the specified pattern from the --graphviz and --image output. Example --filter-pattern="Tests"'],
        ].concat(super)
      end

      def initialize(argv)
        puts 'initialize'.green
        @podspec_name = argv.shift_argument
        @ignore_lockfile = argv.flag?('ignore-lockfile', false)
        @cmd = argv.option('cmd', nil)
        @filter_pattern = argv.option('filter-pattern', nil)
        puts "cmd = #{@cmd}"
        super
      end

      def run
        UI.title "Calculating dependencies"
        puts config.lockfile
        puts config.installation_root

        config_file_path = "#{config.installation_root}/PodBinaryCacheConfig.json"
        if not File.exists?(config_file_path)
          raise "#{config_file_path} not exist"
        end

        if @cmd == 'fetch'
          puts 'fetch'.green
          system "python3 #{__dir__}/PythonScripts/prebuild_lib_cli.py --cmd=fetch --config_path=#{config_file_path}"
        elsif @cmd == 'prebuild'
          puts 'prebuild'.green
          system "python3 #{__dir__}/PythonScripts/prebuild_lib_cli.py --cmd=prebuild --config_path=#{config_file_path}"
        end
      end
    end
  end
end
