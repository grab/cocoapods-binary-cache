require "parallel"
require_relative "base"
require_relative "../helper/zip"

module PodPrebuild
  class CacheFetcher < CommandExecutor
    attr_reader :cache_branch

    def initialize(options)
      super(options)
      @cache_branch = options[:cache_branch]
    end

    def run
      Pod::UI.step("Fetching cache") do
        if @config.local_cache?
          print_message_for_local_cache(@config.cache_path)
        else
          fetch_remote_cache(@config.cache_repo, @cache_branch, @config.cache_path)
        end
        unzip_cache
      end
    end

    private

    def print_message_for_local_cache(cache_dir)
      Pod::UI.puts "You're using local cache at: #{cache_dir}.".yellow
      message = <<~HEREDOC
        To enable remote cache (with a git repo), add the `remote` field to the repo config in the `cache_repo` option.
        For more details, check out this doc:
          https://github.com/grab/cocoapods-binary-cache/blob/master/docs/configure_cocoapods_binary_cache.md#cache_repo-
      HEREDOC
      Pod::UI.puts message
    end

    def fetch_remote_cache(repo, branch, dest_dir)
      Pod::UI.puts "Fetching cache from #{repo} (branch: #{branch})".green
      if Dir.exist?(dest_dir + "/.git")
        begin
          git("fetch origin #{branch}")
        rescue
          git("fetch --depth 10 origin", can_fail: true)
        end
        git("checkout -f FETCH_HEAD", ignore_output: true)
        git("branch -D #{branch}", ignore_output: true, can_fail: true)
        git("checkout -b #{branch}")
      else
        FileUtils.rm_rf(dest_dir)
        begin
          git_clone("--depth=1 --branch=#{branch} #{repo} #{dest_dir}")
        rescue
          git_clone("--depth=1 #{repo} #{dest_dir}")
          git("checkout -b #{branch}")
        end
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
      zip_paths = Dir[@config.generated_frameworks_dir(in_cache: true) + "/*.zip"]
      Parallel.each(zip_paths, in_threads: 8) do |path|
        ZipUtils.unzip(path, to_dir: @config.generated_frameworks_dir)
      end
    end
  end
end
