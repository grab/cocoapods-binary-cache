Pod::Spec.new do |s|
  s.name             = 'ConfigService'
  s.version          = '0.0.1'
  s.summary          = 'Config Service'

  s.description      = 'ConfigService description'

  s.homepage         = 'https://github.com/example'
  s.license          = 'Grab'
  s.author           = 'GrabTaxi Holdings Pte Ltd'
  s.source           = { :path => "ExperimentService" }

  s.ios.deployment_target = '10.0'
  s.static_framework = false

  s.source_files = 'Classes/**/*'

  s.dependency 'RxSwift'
  s.dependency 'ConfigSDK'
end
