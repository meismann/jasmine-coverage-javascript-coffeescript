class JasmineCoverageRailtie < Rails::Railtie
  rake_tasks do
    # load "tasks/jasmine_coverage.rake"
    # Dir[File.join(File.dirname(__FILE__),'tasks/*.rake')].each { |f| load f }
  end
end