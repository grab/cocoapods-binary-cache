module PodPrebuild
  class PostInstallHook
    def initialize(installer_context)
      @installer_context = installer_context
    end

    def run
      return unless Pod::Podfile::DSL.enable_prebuild_dev_pod && @installer_context.sandbox.instance_of?(Pod::PrebuildSandbox)
      # Modify pods scheme to support code coverage
      # If we don't prebuild dev pod -> no need to care about this in Pod project
      # because we setup in the main project (ex. DriverCI scheme)
      SchemeEditor.edit_to_support_code_coverage(@installer_context.sandbox) if Pod.is_prebuild_stage
    end
  end
end
