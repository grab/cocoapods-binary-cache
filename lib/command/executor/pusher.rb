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
        commit_message = "Update prebuilt cache".shellescape
        git("add .")
        git("commit -m '#{commit_message}'")
        git("push origin #{@cache_branch}")
      end
    end
  end
end
