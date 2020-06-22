module PodPrebuild
  class CommandExecutor
    def initialize(options)
      @config = options[:config]
    end

    def git(cmd, options = {})
      comps = ["git"]
      comps << "-C" << @config.cache_path unless options[:cache_repo] == false
      comps << cmd
      comps << "&> /dev/null" if options[:ignore_output]
      comps << "|| true" if options[:can_fail]
      `#{comps.join(" ")}`
    end

    def git_clone(cmd, options = {})
      git("clone #{cmd}", options.merge(:cache_repo => false))
    end
  end
end
