require_relative "base"

module PodPrebuild
  class IntegrationDiagnosis < BaseDiagnosis
    def run
      should_be_integrated = if Pod::Podfile::DSL.prebuild_job? \
                             then @cache_validation.hit + @cache_validation.missed \
                             else @cache_validation.hit \
                             end
      should_be_integrated = should_be_integrated.map { |name| name.split("/")[0] }.to_set
      unintegrated = should_be_integrated.reject do |name|
        framework_path = @standard_sandbox.pod_dir(name) + "#{name}.framework"
        framework_path.exist?
      end
      Pod::UI.puts "🚩 Unintegrated frameworks: #{unintegrated}".yellow unless unintegrated.empty?
    end
  end
end
