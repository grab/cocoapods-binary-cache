require_relative "../source_installer"

module Pod
  class Installer
    # Override the download step to skip download and prepare file in target folder
    define_method(:install_source_of_pod) do |pod_name|
      pod_installer = create_pod_installer(pod_name)
      # Injected code
      # ------------------------------------------
      if should_integrate_prebuilt_pod?(pod_name)
        pod_installer.install_for_prebuild!(sandbox)
      else
        pod_installer.install!
      end
      # ------------------------------------------
      @installed_specs.concat(pod_installer.specs_by_platform.values.flatten.uniq)
    end

    def should_integrate_prebuilt_pod?(name)
      if Pod::Podfile::DSL.prebuild_job?
        # In a prebuild job, at the integration stage, all prebuilt frameworks should be
        # ready for integration regardless of whether there was any cache miss or not.
        # Those that are missed were prebuilt in the prebuild stage.
        PodPrebuild::StateStore.cache_validation.include?(name)
      else
        PodPrebuild::StateStore.cache_validation.hit?(name)
      end
    end
  end
end
