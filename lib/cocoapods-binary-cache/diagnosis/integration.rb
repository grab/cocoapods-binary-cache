require_relative "base"

module PodPrebuild
  class IntegrationDiagnosis < BaseDiagnosis
    def run
      should_be_integrated = if PodPrebuild.config.prebuild_job? \
                             then @cache_validation.hit + @cache_validation.missed \
                             else @cache_validation.hit \
                             end
      should_be_integrated = should_be_integrated.map { |name| name.split("/")[0] }.to_set
      unintegrated = should_be_integrated.reject do |name|
        module_name = spec(name)&.module_name || name
        framework_path = \
          @standard_sandbox.pod_dir(name) + \
          PodPrebuild.config.prebuilt_path(path: "#{module_name}.framework")
        framework_path.exist?
      end
      return [] if unintegrated.empty?

      [[:error, "Unintegrated frameworks: #{unintegrated}"]]
    end
  end
end
