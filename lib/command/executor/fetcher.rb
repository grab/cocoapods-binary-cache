require_relative "base"
require_relative "../helper/zip"

module PodPrebuild
  class CacheFetcher < CommandExecutor
    def initialize(options)
      super(options)
      @cache_branch = options[:cache_branch]
    end

    def run
      Pod::UI.step("Fetching cache") do
        fetch_cache(@config.cache_repo, @cache_branch, @config.cache_path)
        unzip_cache
      end
    end

    private

    def fetch_cache(repo, branch, dest_dir)
      Pod::UI.puts "Fetching cache from #{repo} (branch: #{branch})".green
      if Dir.exist?(dest_dir + "/.git")
        git("fetch origin #{branch}")
        git("checkout -f FETCH_HEAD", ignore_output: true)
        git("branch -D #{branch}", ignore_output: true, can_fail: true)
        git("checkout -b #{branch}")
      else
        FileUtils.rm_rf(dest_dir)
        git_clone("--depth=1 --branch=#{branch} #{repo} #{dest_dir}")
      end
    end

    def unzip_cache
      Pod::UI.puts "Unzipping cache: #{@config.cache_path} -> #{@config.prebuild_sandbox_path}".green
      FileUtils.rm_rf(@config.prebuild_sandbox_path)
      FileUtils.mkdir_p(@config.prebuild_sandbox_path)

      if File.exist?(@config.manifest_path(in_cache: true))
        FileUtils.cp(
          @config.manifest_path(in_cache: true),
          @config.manifest_path
        )
      end
      Dir[@config.generated_frameworks_dir(in_cache: true) + "/*.zip"].each do |path|
        ZipUtils.unzip(path, to_dir: @config.generated_frameworks_dir)
      end
    end
  end
end
