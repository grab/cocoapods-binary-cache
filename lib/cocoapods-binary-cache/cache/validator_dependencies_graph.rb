module PodPrebuild
  class DependenciesGraphCacheValidator < BaseCacheValidator
    def validate(validation)
      return PodPrebuild::CacheValidationResult.new if library_evolution_supported? || @pod_lockfile.nil?

      dependencies_graph = DependenciesGraph.new(@pod_lockfile.lockfile)
      clients = dependencies_graph.get_clients(validation.missed.to_a)
      unless Pod::Podfile::DSL.dev_pods_enabled
        clients = clients.reject { |client| @pod_lockfile.dev_pods.keys.include?(client) }
      end

      missed = clients.map { |client| [client, "Dependencies were missed"] }.to_h
      PodPrebuild::CacheValidationResult.new(missed, Set.new)
    end

    def library_evolution_supported?
      false
    end
  end
end
