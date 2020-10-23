require_relative "executor/prebuilder"
require_relative "../cocoapods-binary-cache/pod-binary/prebuild_dsl"

module Pod
  class Command
    class Binary < Command
      class Prebuild < Binary
        self.arguments = [CLAide::Argument.new("CACHE-BRANCH", false)]
        def self.options
          [
            ["--config", "Config (Debug, Test...) to prebuild"],
            ["--repo-update", "Update pod repo before installing"],
            ["--push", "Push cache to repo upon completion"],
            ["--all", "Prebuild all binary pods regardless of cache validation"],
            ["--targets", "Targets to prebuild. Use comma (,) to specify a list of targets"]
          ].concat(super)
        end

        def initialize(argv)
          super
          prebuild_all_pods = argv.flag?("all")
          prebuild_targets = argv.option("targets", "").split(",")
          update_cli_config(
            :prebuild_job => true,
            :prebuild_all_pods => prebuild_all_pods,
            :prebuild_config => argv.option("config")
          )
          update_cli_config(:prebuild_targets => prebuild_targets) unless prebuild_all_pods
          @prebuilder = PodPrebuild::CachePrebuilder.new(
            config: prebuild_config,
            cache_branch: argv.shift_argument || "master",
            repo_update: argv.flag?("repo-update"),
            push_cache: argv.flag?("push")
          )
        end

        def run
          @prebuilder.run
        end
      end
    end
  end
end
