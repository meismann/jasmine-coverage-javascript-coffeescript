# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jasmine-coverage-javascript-coffeescript/version'

Gem::Specification.new do |s|
  s.name = "jasmine-coverage-javascript-coffeescript"
  s.version = JasmineCoverageJavaScriptCoffeeScript::VERSION

  # s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors     = ["Harry Lascelles", "Martin Eismann"]
  s.email       = ["martin.eismann@injixo.com"]
  s.description = "A blend of JS/CoffeeScript unit testing and coverage"
  s.summary     = s.description
  s.files       = `git ls-files`.split($/)
  s.homepage    = "https://github.com/meismann/jasmine-coverage-javascript-coffeescript"
  s.license     = 'GNU'
  s.require_paths = ["lib"]

  s.add_dependency(%q<jasmine-headless-webkit>, [">= 0.9.0.rc.2"])
  s.add_dependency(%q<coffee-script-source>, [">= 0"])
  
  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rake"
end
