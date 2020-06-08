module PodPrebuild
  class StateStore
    @excluded_pods = Set.new
    class << self
      attr_accessor :excluded_pods
    end
  end
end
