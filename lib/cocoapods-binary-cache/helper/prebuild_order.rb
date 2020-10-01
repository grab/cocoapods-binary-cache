module PodPrebuild
  module BuildOrder
    def self.order_targets(targets)
      # It's more efficient to build frameworks that have more dependencies first
      # so that the build parallelism is ultilized
      # >> --- MyFramework ----------------------------------|
      #        >> --- ADependency ---|
      #          >> --- AnotherADependency ---|
      targets.sort_by { |t| -t.recursive_dependent_targets.count }
    end
  end
end
