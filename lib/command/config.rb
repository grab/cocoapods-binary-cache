require_relative "../cocoapods-binary-cache/helper/json"

module PodPrebuild
  def self.config
    PodPrebuild::Config.instance
  end

  class Config # rubocop:disable Metrics/ClassLength
    attr_accessor :dsl_config, :cli_config

    def initialize(path)
      @deprecated_config = File.exist?(path) ? PodPrebuild::JSONFile.new(path).data : {}
      @dsl_config = {}
      @cli_config = {}
      @detected_config = {}
    end

    def self.instance
      @instance ||= new("PodBinaryCacheConfig.json")
    end

    def reset!
      @deprecated_config = {}
      @dsl_config = {}
      @cli_config = {}
    end

    def cache_repo
      @cache_repo ||= cache_repo_config["remote"]
    end

    def local_cache?
      cache_repo.nil?
    end

    def cache_path
      @cache_path ||= File.expand_path(cache_repo_config["local"])
    end

    def prebuild_sandbox_path
      @dsl_config[:prebuild_sandbox_path] || @deprecated_config["prebuild_path"] || "_Prebuild"
    end

    def prebuild_delta_path
      @dsl_config[:prebuild_delta_path] || @deprecated_config["prebuild_delta_path"] || "_Prebuild_delta/changes.json"
    end

    def manifest_path(in_cache: false)
      root_dir(in_cache) + "/Manifest.lock"
    end

    def root_dir(in_cache)
      in_cache ? cache_path : prebuild_sandbox_path
    end

    def generated_frameworks_dir(in_cache: false)
      root_dir(in_cache) + "/GeneratedFrameworks"
    end

    def prebuilt_path(path: nil)
      p = Pathname.new(path.nil? ? "_Prebuilt" : "_Prebuilt/#{path}")
      p = p.sub_ext(".xcframework") if xcframework? && p.extname == ".framework"
      p.to_s
    end

    def validate_dsl_config
      inapplicable_options = @dsl_config.keys - applicable_dsl_config
      return if inapplicable_options.empty?

      message = <<~HEREDOC
        [WARNING] The following options (in `config_cocoapods_binary_cache`) are not correct: #{inapplicable_options}.
        Available options: #{applicable_dsl_config}.
        Check out the following doc for more details
          https://github.com/grab/cocoapods-binary-cache/blob/master/docs/configure_cocoapods_binary_cache.md
      HEREDOC

      Pod::UI.puts message.yellow
    end

    def prebuild_config
      @cli_config[:prebuild_config] || @dsl_config[:prebuild_config] || "Debug"
    end

    def prebuild_job?
      @cli_config[:prebuild_job] || @dsl_config[:prebuild_job]
    end

    def prebuild_all_pods?
      @cli_config[:prebuild_all_pods] || @dsl_config[:prebuild_all_pods]
    end

    def excluded_pods
      ((@dsl_config[:excluded_pods] || Set.new) + (@detected_config[:excluded_pods] || Set.new)).to_set
    end

    def dev_pods_enabled?
      @dsl_config[:dev_pods_enabled]
    end

    def bitcode_enabled?
      @dsl_config[:bitcode_enabled]
    end

    def device_build_enabled?
      @dsl_config[:device_build_enabled]
    end

    def xcframework?
      @dsl_config[:xcframework]
    end

    def disable_dsym?
      @dsl_config[:disable_dsym]
    end

    def dont_remove_source_code?
      @dsl_config[:dont_remove_source_code]
    end

    def build_args
      @dsl_config[:build_args]
    end

    def save_cache_validation_to
      @dsl_config[:save_cache_validation_to]
    end

    def validate_prebuilt_settings
      @dsl_config[:validate_prebuilt_settings]
    end

    def prebuild_code_gen
      @dsl_config[:prebuild_code_gen]
    end

    def strict_diagnosis?
      @dsl_config[:strict_diagnosis]
    end

    def silent_build?
      @dsl_config[:silent_build]
    end

    def targets_to_prebuild_from_cli
      @cli_config[:prebuild_targets] || []
    end

    def update_detected_prebuilt_pod_names!(value)
      @detected_config[:prebuilt_pod_names] = value
    end

    def update_detected_excluded_pods!(value)
      @detected_config[:excluded_pods] = value
    end

    def prebuilt_pod_names
      @detected_config[:prebuilt_pod_names] || Set.new
    end

    def tracked_prebuilt_pod_names
      prebuilt_pod_names - excluded_pods
    end

    private

    def applicable_dsl_config
      [
        :cache_repo,
        :prebuild_sandbox_path,
        :prebuild_delta_path,
        :prebuild_config,
        :prebuild_job,
        :prebuild_all_pods,
        :excluded_pods,
        :dev_pods_enabled,
        :bitcode_enabled,
        :device_build_enabled,
        :xcframework,
        :disable_dsym,
        :dont_remove_source_code,
        :build_args,
        :save_cache_validation_to,
        :validate_prebuilt_settings,
        :prebuild_code_gen,
        :strict_diagnosis,
        :silent_build
      ]
    end

    def cache_repo_config
      @cache_repo_config ||= begin
        repo = @cli_config[:repo] || "default"
        config_ = @dsl_config[:cache_repo] || {}
        if config_[repo].nil?
          message = <<~HEREDOC
            [Deprecated] Configs in `PodBinaryCacheConfig.json` are deprecated.
            Declare option `cache_repo` in `config_cocoapods_binary_cache` instead.
            Check out the following doc for more details
              https://github.com/grab/cocoapods-binary-cache/blob/master/docs/configure_cocoapods_binary_cache.md
          HEREDOC
          Pod::UI.puts message.yellow
        end
        config_[repo] || {
          "remote" => @deprecated_config["cache_repo"] || @deprecated_config["prebuilt_cache_repo"],
          "local" => @deprecated_config["cache_path"] || "~/.cocoapods-binary-cache/prebuilt-frameworks"
        }
      end
    end
  end
end
