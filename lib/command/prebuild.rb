require_relative "executor/prebuilder"
require_relative "../cocoapods-binary-cache/pod-binary/prebuild_dsl"

module Pod
  class Command
    class Binary < Command
      class Prebuild < Binary
        self.arguments = [CLAide::Argument.new("CACHE-BRANCH", false)]
        def self.options
          [
            ["--push", "Push cache to repo upon completion"],
            ["--all", "Prebuild all binary pods regardless of cache validation"],
            ["--targets", "Targets to prebuild. Use comma (,) to specify a list of targets"]
          ]
        end

        def initialize(argv)
          super
          @prebuild_all_pods = argv.flag?("all")
          @prebuild_targets = argv.option("targets", "").split(",")
          @prebuilder = PodPrebuild::CachePrebuilder.new(
            config: prebuild_config,
            cache_branch: argv.shift_argument || "master",
            push_cache: argv.flag?("push")
          )
        end

        def run
          Pod::Podfile::DSL.binary_cache_cli_config[:prebuild_job] = true
          Pod::Podfile::DSL.binary_cache_cli_config[:prebuild_all_pods] = @prebuild_all_pods
          Pod::Podfile::DSL.binary_cache_cli_config[:prebuild_targets] = @prebuild_targets unless @prebuild_all_pods
          @prebuilder.run
        end
      end
    end
  end
end
