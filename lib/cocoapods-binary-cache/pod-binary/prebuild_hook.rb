require_relative "helper/feature_switches"
require_relative "helper/passer"
require_relative "helper/podfile_options"
require_relative "helper/prebuild_sandbox"

Pod::HooksManager.register("cocoapods-binary-cache", :pre_install) do |installer_context|
  PodPrebuild::PreInstallHook.new(installer_context).run
end

Pod::HooksManager.register("cocoapods-binary-cache", :post_install) do |installer_context|
  PodPrebuild::PostInstallHook.new(installer_context).run
end
