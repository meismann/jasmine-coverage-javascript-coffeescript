lib_dir = File.expand_path(File.dirname(__FILE__) + '/lib')
$LOAD_PATH << lib_dir unless $LOAD_PATH.include?(lib_dir)

require 'jasmine/coverage'

Gem::Specification.new do |s|
  s.name = 'jasmine-coverage-javascript-coffeescript'
  s.version = Jasmine::Coverage::VERSION
  s.authors = ['Harry Lascelles', 'Martin Eismann']
  s.email = ['martin.eismann@injixo.com']
  s.homepage = 'https://github.com/firstbanco/jasmine-coverage'
  s.summary = 'A blend of JS/CoffeeScript unit testing and coverage'

  s.files = Dir["{lib}/**/*"] + ["README.md"]
  s.require_paths = ['lib']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'jasmine-headless-webkit', '>=0.9.0.rc.2'
  s.add_dependency 'coffee-script-source'
end