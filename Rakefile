env = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
if env =~ /^(development|test)$/
  import 'lib/tasks/jasmine_coverage.rake'
end