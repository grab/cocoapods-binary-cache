Pod::Spec.new do |s|
  s.name             = 'ConfigSDK'
  s.version          = '0.0.1'
  s.summary          = 'A short description'

  s.description      = 'ConfigSDK description'

  s.homepage         = 'https://github.com/example'
  s.license          = 'Grab'
  s.author           = { "Bang" => "bang@grabtaxi.com" }
  s.source           = { :git => 'https://gitlab.myteksi.net/mobile/dax-ios/driver-ios', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.static_framework = false

  s.source_files = 'Classes/**/*'

  s.dependency 'SQLite.swift'
  s.dependency 'ProtocolBuffers-Swift'
end
