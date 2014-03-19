# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'samurai/version'

Gem::Specification.new do |spec|
  spec.name          = 'samurai'
  spec.version       = Samurai::VERSION
  spec.authors       = ['Nick DeMonner']
  spec.email         = ['ndemonner@zenpayroll.com']
  spec.summary       = 'Service framework for exposing and consuming resources via RabbitMQ'
  spec.description   = ''
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'bunny', '~> 1.1'
  spec.add_dependency 'activemodel', '~> 4.0'
  spec.add_dependency 'activesupport', '~> 4.0'
  spec.add_dependency 'yell'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  # spec.add_development_dependency 'rspec-collection_matchers'
end
