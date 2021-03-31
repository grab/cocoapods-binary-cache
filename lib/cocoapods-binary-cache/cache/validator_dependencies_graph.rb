module PodPrebuild
  class DependenciesGraphCacheValidator < AccumulatedCacheValidator
    def initialize(options)
      super(options)
      @ignored_pods = options[:ignored_pods] || Set.new
    end

    def validate(accumulated)
      return accumulated if library_evolution_supported? || @pod_lockfile.nil?

      dependencies_graph = DependenciesGraph.new(lockfile: @pod_lockfile.lockfile, invert_edge: true)
      clients = dependencies_graph.get_clients(accumulated.discard(@ignored_pods).missed.to_a)
      unless PodPrebuild.config.dev_pods_enabled?
        clients = clients.reject { |client| @pod_lockfile.dev_pods.keys.include?(client) }
      end

      missed = clients.map { |client| [client, "Dependencies were missed"] }.to_h
      accumulated.merge(PodPrebuild::CacheValidationResult.new(missed, Set.new))
    end

    def library_evolution_supported?
      false
    end
  end
end
