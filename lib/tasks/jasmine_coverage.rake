require 'pp'

module Jasmine
  module CoverageConfig
  
    def self.output_dir
      File.expand_path('coverage/coffee_and_javascript')
    end
  
    def self.instrumented_dir
      output_dir + '/instrumented/'
    end

    # The reprocessing folder map
    def self.files_map
      {
        File.expand_path('app/assets/javascripts') => instrumented_dir+'app',
        File.expand_path('lib/assets/javascripts') => instrumented_dir+'lib',
        File.expand_path('public/javascripts') => instrumented_dir+'public'
      }
    end
    
    def self.internal_test_exec_file
      output_dir + '/internal_test_executer.html'
    end
  end
end


env = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
if env =~ /^(development|test)$/
  require 'rake'
  require 'base64'

  namespace :jasmine do
    desc 'Runs Jasmine with a coverage report for javascript and coffeescript files'
    task :coverage do

      require 'jasmine-headless-webkit'
      # Instill our patches for jasmine-headless to work
      require_relative 'jasmine_headless_coverage_patches'

      # Preprocess the JS files to add instrumentation
      FileUtils.rm_rf Jasmine::CoverageConfig.output_dir
      FileUtils.mkdir_p Jasmine::CoverageConfig.instrumented_dir

      # Instrument the source files into the instrumented folders
      Jasmine::CoverageConfig.files_map.each do |source, instrumented|
        instrument_js source, instrumented
        instrument_cs source, instrumented
        # Also hoist up the eventual viewing files
        FileUtils.mv(Dir.glob(instrumented+'/jscoverage*'), Jasmine::CoverageConfig.output_dir)
      end

      puts "\nCoverage will now be run. Expect a large block of compiled coverage data. This will be processed for you into target/jscoverage.\n\n"

      # Run Jasmine using the original config.
      status_code = Jasmine::Headless::Runner.run(
          # Any options from the options.rb file in jasmine-headless-webkit can be used here.
          :reporters => [['File', "#{Jasmine::CoverageConfig.output_dir}/rawreport.txt"]]
      )

      if status_code == 1
        fail <<-ERR_NOTE
JSCoverage exited with error code: #{status_code}.

This implies one of five things:

1) Your JS files had exactly zero instructions. Are they all blank or just comments?
2) A test failed (open #{Jasmine::CoverageConfig.internal_test_exec_file} with your browser to see which tests are concerned. \
HINT: Use FF, since Chrome has strict security settings that make this difficult; the page accesses the local filesystem from \
Javascript (but you can switch the settings off at the command line))
3) The sourcecode has a syntax error (which JSLint should find)
4) An error occurred in a deferred block, eg a setTimeout or underscore _.defer. This caused a window error which Jasmine will never see.
5) The source files are being loaded out of sequence (so global variables are not being declared in order)
   To check this, run bundle exec jasmine-headless-webkit -l to see the ordering

In any case, try running the standard jasmine-headless-webkit command to get better errors:
  jasmine-headless-webkit -c

        ERR_NOTE
      end

      # Obtain the console log, which includes the coverage report encoded within it
      contents = File.open("#{Jasmine::CoverageConfig.output_dir}/rawreport.txt") { |f| f.read }
      # Get our Base64.
      json_report_enc = contents.split(/ENCODED-COVERAGE-EXPORT-STARTS:/m)[1]
      # Remove the junk at the end
      json_report_enc_stripped = json_report_enc[0, json_report_enc.index("\"")]

      # Unpack it from Base64
      json_report = Base64.decode64(json_report_enc_stripped)

      # Save the coverage report where the GUI html expects it to be
      File.open("#{Jasmine::CoverageConfig.output_dir}/jscoverage.json", 'w') { |f| f.write(json_report) }

      # Modify the jscoverage.html so it knows it is showing a report, not running a test
      File.open("#{Jasmine::CoverageConfig.output_dir}/jscoverage.js", 'a') { |f| f.write("\njscoverage_isReport = true;") }

      if json_report_enc.index("No Javascript was found to test coverage for").nil?
        # Check for coverage failure
        total_location = json_report_enc.index("% Total")
        coverage_pc = json_report_enc[total_location-3, 3].to_i

        conf = (ENV['JSCOVERAGE_MINIMUM'] || ENV['JASMINE_COVERAGE_MINIMUM'])
        fail "Coverage Fail: Javascript coverage was less than #{conf}%. It was #{coverage_pc}%." if conf && coverage_pc < conf.to_i
      end

    end

    def instrument_js folder, instrumented_dir
      _instrument folder, instrumented_dir, 'jscoverage', '-v'
    end
    
    def instrument_cs folder, instrumented_dir
      _instrument folder, instrumented_dir, 'coffeeCoverage', '--verbose'
    end
    
    def _instrument folder, instrumented_dir, exec, option= ''
      return unless File.directory? folder
      
      fail '#{exec} executable not found in PATH' if %x(which #{exec}).empty?
      unless system "#{exec} #{option} #{folder} #{instrumented_dir}"
        fail "Instrumenting failed. Error message from system: #{$?}"
      end
    end
  end
end