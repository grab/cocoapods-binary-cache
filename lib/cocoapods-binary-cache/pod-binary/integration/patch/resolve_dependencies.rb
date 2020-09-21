# Let cocoapods use the prebuild framework files in install process.
#
# the code only effect the second pod install process.
#
module Pod
  class Installer
    # Modify specification to use only the prebuild framework after analyzing
    original_resolve_dependencies = instance_method(:resolve_dependencies)
    define_method(:resolve_dependencies) do
      original_resolve_dependencies.bind(self).call

      # check the pods
      # Although we have did it in prebuild stage, it's not sufficient.
      # Same pod may appear in another target in form of source code.
      # Prebuild.check_one_pod_should_have_only_one_target(prebuilt_pod_targets)
      validate_every_pod_only_have_one_form
      alter_specs_for_prebuilt_pods
    end
  end
end
