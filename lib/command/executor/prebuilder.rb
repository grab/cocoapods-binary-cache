require_relative "base"
require_relative "fetcher"
require_relative "pusher"

module PodPrebuild
  class CachePrebuilder < CommandExecutor
    def initialize(options)
      super(options)
      @cache_branch = options[:cache_branch]
      @push_cache = options[:push_cache]
      @fetcher = PodPrebuild::CacheFetcher.new(options)
      @pusher = PodPrebuild::CachePusher.new(options)
    end

    def run
      @fetcher.run
      prebuild
      changes = PodPrebuild::JSONFile.new(@config.prebuild_delta_path)
      return if changes.empty?

      sync_cache(changes)
      @pusher.run if @push_cache
    end

    private

    def prebuild
      Pod::UI.step("Installation") do
        args = []
        args << "--ansi" if Pod::Command.ansi_output?
        Pod::Command::Install.new(CLAide::ARGV.new(args)).run
      end
    end

    def sync_cache(changes)
      Pod::UI.step("Syncing cache") do
        FileUtils.cp(@config.manifest_path, @config.manifest_path(in_cache: true))
        clean_cache(changes["deleted"])
        zip_to_cache(changes["updated"])
      end
    end

    def zip_to_cache(pods_to_update)
      FileUtils.mkdir_p(@config.generated_frameworks_dir(in_cache: true))
      pods_to_update.each do |pod|
        Pod::UI.puts "- Update cache: #{pod}"
        ZipUtils.zip(
          "#{@config.generated_frameworks_dir}/#{pod}",
          to_dir: @config.generated_frameworks_dir(in_cache: true)
        )
      end
    end

    def clean_cache(pods_to_delete)
      pods_to_delete.each do |pod|
        Pod::UI.puts "- Clean up cache: #{pod}"
        FileUtils.rm_rf("#{@config.generated_frameworks_dir(in_cache: true)}/#{pod}.zip")
      end
    end
  end
end
