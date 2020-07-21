# ABOUT NAMES
#
# There are many kinds of name in cocoapods. Two main names are widely used in this plugin.
# - root_spec.name (spec.root_name, targe.pod_name):
#   aka "pod_name"
#   the name we use in podfile. the concept.
#
# - target.name:
#   aka "target_name"
#   the name of the final target in xcode project. the final real thing.
#
# One pod may have multiple targets in xcode project, due to one pod can be used in mutiple
# platform simultaneously. So one `root_spec.name` may have multiple coresponding `target.name`s.
# Therefore, map a spec to/from targets is a little complecated. It's one to many.
#

# Tool to transform Pod_name to target efficiently
module Pod
  def self.fast_get_targets_for_pod_name(pod_name, targets, cache)
    pod_name = pod_name.split("/")[0] # Look for parent spec instead of subspecs
    if cache.empty?
      targets.select { |target| target.name == pod_name }
    else
      cache.first[pod_name] || []
    end
  end
end
