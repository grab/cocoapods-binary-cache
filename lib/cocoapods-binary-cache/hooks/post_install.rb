module PodPrebuild
  class PostInstallHook
    def initialize(installer_context)
      @installer_context = installer_context
    end

    def run
      edit_scheme_for_code_coverage if PodPrebuild::Env.prebuild_stage?
      diagnose if PodPrebuild::Env.integration_stage?
    end

    private

    def diagnose
      Pod::UI.section("Diagnosing cocoapods-binary-cache") do
        PodPrebuild::Diagnosis.new(
          cache_validation: PodPrebuild::StateStore.cache_validation,
          standard_sandbox: @installer_context.sandbox,
          specs: @installer_context.umbrella_targets.map(&:specs).flatten
        ).run
      end
    end

    def edit_scheme_for_code_coverage
      return unless Pod::Podfile::DSL.dev_pods_enabled? && @installer_context.sandbox.instance_of?(Pod::PrebuildSandbox)

      # Modify pods scheme to support code coverage
      # If we don't prebuild dev pod -> no need to care about this in Pod project
      # because we setup in the main project (ex. DriverCI scheme)
      SchemeEditor.edit_to_support_code_coverage(@installer_context.sandbox)
    end
  end
end
