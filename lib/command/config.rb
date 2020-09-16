require_relative "../cocoapods-binary-cache/helper/json"

module PodPrebuild
  def self.config
    PodPrebuild::Config.instance
  end

  class Config
    attr_reader :cache_repo, :cache_path, :prebuild_sandbox_path, :prebuild_delta_path
    attr_accessor :dsl_config, :cli_config

    def initialize(path)
      @data = File.exist?(path) ? PodPrebuild::JSONFile.new(path) : {}
      @cache_repo = @data["cache_repo"] || @data["prebuilt_cache_repo"]
      @cache_path = @data.empty? ? nil : File.expand_path(@data["cache_path"])
      @prebuild_sandbox_path = @data["prebuild_path"] || "_Prebuild"
      @prebuild_delta_path = @data["prebuild_delta_path"] || "_Prebuild_delta/changes.json"
      @dsl_config = {}
      @cli_config = {}
    end

    def self.instance
      @instance ||= new("PodBinaryCacheConfig.json")
    end

    def manifest_path(in_cache: false)
      root_dir(in_cache) + "/Manifest.lock"
    end

    def root_dir(in_cache)
      in_cache ? @cache_path : @prebuild_sandbox_path
    end

    def generated_frameworks_dir(in_cache: false)
      root_dir(in_cache) + "/GeneratedFrameworks"
    end

    def prebuilt_path(path: nil)
      path.nil? ? "_Prebuilt" : "_Prebuilt/#{path}"
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
      @dsl_config[:prebuild_config] || "Debug"
    end

    def prebuild_job?
      @cli_config[:prebuild_job] || @dsl_config[:prebuild_job]
    end

    def prebuild_all_pods?
      @cli_config[:prebuild_all_pods] || @dsl_config[:prebuild_all_pods]
    end

    def excluded_pods
      @dsl_config[:excluded_pods] || Set.new
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

    def targets_to_prebuild_from_cli
      @cli_config[:prebuild_targets] || []
    end

    private

    def applicable_dsl_config
      [
        :prebuild_config,
        :prebuild_job,
        :prebuild_all_pods,
        :excluded_pods,
        :dev_pods_enabled,
        :bitcode_enabled,
        :device_build_enabled,
        :disable_dsym,
        :dont_remove_source_code,
        :build_args,
        :save_cache_validation_to,
        :validate_prebuilt_settings,
        :prebuild_code_gen
      ]
    end
  end
end
