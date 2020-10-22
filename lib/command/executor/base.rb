module PodPrebuild
  class CommandExecutor
    def initialize(options)
      @config = options[:config]
    end

    def installer
      @installer ||= begin
        pod_config = Pod::Config.instance
        Pod::Installer.new(pod_config.sandbox, pod_config.podfile, pod_config.lockfile)
      end
    end

    def git(cmd, options = {})
      comps = ["git"]
      comps << "-C" << @config.cache_path unless options[:cache_repo] == false
      comps << cmd
      comps << "&> /dev/null" if options[:ignore_output]
      comps << "|| true" if options[:can_fail]
      cmd = comps.join(" ")
      raise "Fail to run command '#{cmd}'" unless system(cmd)
    end

    def git_clone(cmd, options = {})
      git("clone #{cmd}", options.merge(:cache_repo => false))
    end
  end
end
