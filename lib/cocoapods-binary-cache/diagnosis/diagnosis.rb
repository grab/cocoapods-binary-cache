require_relative "base"
require_relative "integration"

module PodPrebuild
  class Diagnosis
    def initialize(options)
      @diagnosers = [
        IntegrationDiagnosis
      ].map { |klazz| klazz.new(options) }
    end

    def run
      diagnosis = @diagnosers.map(&:run)
      errors = diagnosis.select { |d| d[0] == :error }.map { |d| d[1] }
      warnings = diagnosis.select { |d| d[0] == :error }.map { |d| d[1] }

      warnings.each { |d| Pod::UI.puts "⚠️  #{d[1]}" }
      errors.each { |d| Pod::UI.puts "🚩  #{d[1]}" }
      return if errors.empty? || !PodPrebuild.config.strict_diagnosis?

      raise "There are #{errors.count} error(s) spotted after the diagnosis"
    end
  end
end
