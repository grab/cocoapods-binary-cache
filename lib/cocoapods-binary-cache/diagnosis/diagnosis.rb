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
      @diagnosers.each(&:run)
    end
  end
end
