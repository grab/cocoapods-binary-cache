Pod::Spec.new do |s|
  s.name             = "UICommonsDynamic"
  s.version          = "0.0.1"
  s.summary          = "UICommonsDynamic"
  s.description      = "UICommonsDynamic"
  s.homepage         = "https://github.com/grab/cocoapods-binary-cache"
  s.license          = "Grab"
  s.author           = "GrabTaxi Holdings Pte Ltd"
  s.source           = { :git => "https://github.com/grab/cocoapods-binary-cache.git", :tag => s.version.to_s }

  s.ios.deployment_target = "10.0"

  s.source_files = "Classes/**/*"
  s.resource_bundle = {
    "UICommonsDynamic" => ["Resources/**/*.json"]
  }

  s.frameworks = "UIKit"
end
