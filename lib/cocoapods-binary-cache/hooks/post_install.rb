module PodPrebuild
  class PostInstallHook
    def initialize(installer_context)
      @installer_context = installer_context
    end

    def run
      diagnose if PodPrebuild::Env.integration_stage?
    end

    private

    def diagnose
      Pod::UI.title("Diagnosing cocoapods-binary-cache") do
        PodPrebuild::Diagnosis.new(
          cache_validation: PodPrebuild.state.cache_validation,
          standard_sandbox: @installer_context.sandbox,
          specs: @installer_context.umbrella_targets.map(&:specs).flatten
        ).run
      end
    end
  end
end
