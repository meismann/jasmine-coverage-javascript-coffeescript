lib_dir = File.expand_path(File.dirname(__FILE__) + '/lib')
$LOAD_PATH << lib_dir unless $LOAD_PATH.include?(lib_dir)

require 'jasmine/coverage'

Gem::Specification.new do |s|
  s.name = 'jasmine-coverage'
  s.version = Jasmine::Coverage::VERSION
  s.authors = ['Harry Lascelles']
  s.email = ['harry@harrylascelles.com']
  s.summary = 'A blend of JS unit testing and coverage'

  s.files = Dir["{lib}/**/*"] + ["README.md"]
  s.require_paths = ['lib']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'jasmine-headless-webkit', '>=0.9.0.rc.2'
  s.add_dependency 'coffee-script-source'
  s.add_dependency 'headless'
end