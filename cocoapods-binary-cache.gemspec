# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-binary-cache/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-binary-cache'
  spec.version       = CocoapodsBinary::VERSION
  spec.authors       = ['bang nguyen']
  spec.email         = ['bang.nguyen@grabtaxi.com']
  spec.description   = %q{Reduce build time by building pod frameworks and cache to remote storage, reuse on multiple machines}
  spec.summary       = %q{Reduce build time by building pod frameworks and cache to remote storage, reuse on multiple machines}
  spec.homepage      = 'https://github.com/update_later'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']

  spec.add_dependency "cocoapods", ">= 1.5.0"
  spec.add_dependency "fourflusher", "~> 2.0"
  spec.add_dependency "xcpretty", "~> 0.3.0"

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake', '~> 10.0'
end
