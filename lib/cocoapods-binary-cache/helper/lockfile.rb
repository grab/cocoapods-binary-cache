require_relative "checksum"

module PodPrebuild
  class Lockfile
    attr_reader :lockfile, :data

    def initialize(lockfile)
      @lockfile = lockfile
      @data = lockfile.to_hash
    end

    def pods
      @pods ||= (@data["PODS"] || []).map { |v| pod_from(v) }.to_h
    end

    def external_sources
      @data["EXTERNAL SOURCES"] || {}
    end

    def dev_pod_sources
      @dev_pod_sources ||= external_sources.select { |_, attributes| attributes.key?(:path) } || {}
    end

    def dev_pod_names
      # There are 2 types of external sources:
      # - Development pods: declared with `:path` option in Podfile, corresponding to `:path` in the Lockfile
      # - External remote pods: declared with `:git` option in Podfile, corresponding to `:git` in the Lockfile
      # --------------------
      # EXTERNAL SOURCES:
      #   ADevPod:
      #     :path: path/to/dev_pod
      #   AnExternalRemotePod:
      #     :git: git@remote_url
      #     :commit: abc1234
      # --------------------
      @dev_pod_names ||= dev_pod_sources.keys.to_set
    end

    def dev_pods
      dev_pod_names_ = dev_pod_names
      @dev_pods ||= pods.select { |name, _| dev_pod_names_.include?(name) }
    end

    def non_dev_pods
      dev_pod_names_ = dev_pod_names
      @non_dev_pods ||= pods.reject { |name, _| dev_pod_names_.include?(name) }
    end

    def subspec_vendor_pods
      dev_pod_names_ = dev_pod_names
      @subspec_vendor_pods ||= subspec_pods.reject { |name, _| dev_pod_names_.include?(name) }
    end

    # Return content hash (Hash the directory at source path) of a dev_pod
    # Return nil if it's not a dev_pod
    def dev_pod_hash(pod_name)
      dev_pod_hashes_map[pod_name]
    end

    private

    def subspec_pods
      @subspec_pods ||= pods.keys
        .select { |k| k.include?("/") }
        .group_by { |k| k.split("/")[0] }
    end

    # Generate a map between a dev_pod and it source hash
    def dev_pod_hashes_map
      @dev_pod_hashes_map ||=
        dev_pod_sources.map { |name, attribs| [name, FolderChecksum.git_checksum(attribs[:path])] }.to_h
    end

    # Parse an item under `PODS` section of a Lockfile
    # @param hash_or_string: an item under `PODS` section, could be a Hash (if having dependencies) or a String
    #   Examples:
    # --------------------------
    #   PODS:
    #     - FrameworkA (0.0.1)
    #     - FrameworkB (0.0.2):
    #       - DependencyOfB
    # -------------------------
    # @return [framework_name, version] (for ex. ["AFramework", "0.0.1"])
    def pod_from(hash_or_string)
      name_with_version = hash_or_string.is_a?(Hash) ? hash_or_string.keys[0] : hash_or_string
      match = name_with_version.match(/(\S+) \((\S+)\)/)
      [match[1], match[2]]
    end
  end
end
