# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'jcjc/version'

Gem::Specification.new do |s|
  s.name = "jasmine-coverage-javascript-coffeescript"
  s.version = JasmineCoverageJavaScriptCoffeeScript::VERSION

  s.authors = ["Harry Lascelles", "Martin Eismann"]
  s.date = "2013-04-05"
  s.description = "A blend of JS/CoffeeScript unit testing and coverage"
  s.email = ["martin.eismann@injixo.com"]
  s.files = `git ls-files`.split($/)
  s.homepage = "https://github.com/meismann/jasmine-coverage-javascript-coffeescript"
  s.licenses = ["GNU"]
  s.require_paths = ["lib"]
  s.summary = s.description

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<jasmine-headless-webkit>, [">= 0.9.0.rc.2"])
      s.add_runtime_dependency(%q<coffee-script-source>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.3"])
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<jasmine-headless-webkit>, [">= 0.9.0.rc.2"])
      s.add_dependency(%q<coffee-script-source>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.3"])
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<jasmine-headless-webkit>, [">= 0.9.0.rc.2"])
    s.add_dependency(%q<coffee-script-source>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.3"])
    s.add_dependency(%q<rake>, [">= 0"])
  end
end
