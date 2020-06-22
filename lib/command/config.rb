require_relative "../cocoapods-binary-cache/helper/json"

module PodPrebuild
  class Config
    attr_reader :cache_repo, :cache_path, :prebuild_path

    def initialize(path)
      @data = PodPrebuild::JSONFile.new(path)
      @cache_repo = @data["prebuilt_cache_repo"]
      @cache_path = File.expand_path(@data["cache_path"])
      @prebuild_path = @data["prebuild_path"] || "Pods/_Prebuild"
    end

    def manifest_path(in_cache: false)
      root_dir(in_cache) + "/Manifest.lock"
    end

    def root_dir(in_cache)
      in_cache ? @cache_path : @prebuild_path
    end

    def generated_frameworks_dir(in_cache: false)
      root_dir(in_cache) + "/GeneratedFrameworks"
    end

    def delta_file_path
      # TODO (thuyen): Unify this path with PodPrebuild::Output#delta_file_path
      "Pods/_Prebuild_delta/changes.json"
    end
  end
end
