require_relative "../tool/tool"

module Pod
  class Prebuild
    # Pass the data between the 2 steps
    #
    # At step 2, the normal pod install, it needs some info of the
    # prebuilt step. So we store it here.
    #
    class Passer
      # indicate the add/remove/update of prebuit pods
      # @return [Analyzer::SpecsState]
      #
      class_attr_accessor :prebuild_pods_changes

      # Some pod won't be build in prebuild stage even if it have `binary=>true`.
      # The targets of this pods have `oshould_build? == true`.
      # We should skip integration (patch spec) for this pods
      #
      # @return [Array<String>]
      class_attr_accessor :target_names_to_skip_integration_framework
      self.target_names_to_skip_integration_framework = []
    end

    class CacheInfo
      class_attr_accessor :cache_hit_vendor_pods
      self.cache_hit_vendor_pods = Set[]

      class_attr_accessor :cache_hit_dev_pods_dic
      self.cache_hit_dev_pods_dic = Hash[]

      class_attr_accessor :cache_miss_dev_pods_dic
      self.cache_miss_dev_pods_dic = Hash[]
    end
  end
end
