require_relative "../cocoapods-binary-cache/helper/json"

module PodPrebuild
  class Config
    attr_reader :cache_repo, :cache_path, :prebuild_sandbox_path, :prebuild_delta_path

    def initialize(path)
      @data = PodPrebuild::JSONFile.new(path)
      @cache_repo = @data["cache_repo"] || @data["prebuilt_cache_repo"]
      @cache_path = File.expand_path(@data["cache_path"])
      @prebuild_sandbox_path = @data["prebuild_path"] || "_Prebuild"
      @prebuild_delta_path = @data["prebuild_delta_path"] || "_Prebuild_delta/changes.json"
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
  end
end
