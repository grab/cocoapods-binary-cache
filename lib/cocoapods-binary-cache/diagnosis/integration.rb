require_relative "base"

module PodPrebuild
  class IntegrationDiagnosis < BaseDiagnosis
    def run
      integrated = @standard_sandbox.root.glob("*/*.framework").map { |p| p.dirname.basename.to_s }
      should_be_integrated = if Pod::Podfile::DSL.prebuild_job? \
                             then @cache_validation.hit + @cache_validation.missed \
                             else @cache_validation.hit \
                             end
      should_be_integrated = should_be_integrated.map { |name| name.split("/")[0] }
      unintegrated = (should_be_integrated - integrated)
      Pod::UI.puts "🚩 Unintegrated frameworks: #{unintegrated}".yellow unless unintegrated.empty?
    end
  end
end
