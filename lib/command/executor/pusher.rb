require_relative "base"

module PodPrebuild
  class CachePusher < CommandExecutor
    attr_reader :cache_branch

    def initialize(options)
      super(options)
      @cache_branch = options[:cache_branch]
    end

    def run
      Pod::UI.step("Pushing cache") do
        if @config.local_cache?
          print_message_for_local_cache
        else
          commit_and_push_cache
        end
      end
    end

    private

    def print_message_for_local_cache
      Pod::UI.puts "Skip pushing cache as you're using local cache".yellow
    end

    def commit_and_push_cache
      commit_message = "Update prebuilt cache"
      git("add .")
      git("commit -m '#{commit_message}'", can_fail: true)
      git("push origin #{@cache_branch}")
    end
  end
end
