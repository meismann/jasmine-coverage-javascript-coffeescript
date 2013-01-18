require 'pp'

module Jasmine
  module CoverageConfig
  
    def self.output_dir
      File.join 'coverage', 'coffee_and_javascript'
    end
  
    def self.instrumented_dir
      File.join output_dir, 'instrumented/'
    end

    # The reprocessing folder map
    def self.files_map
      {
        File.join('app', 'assets', 'javascripts') => File.join(instrumented_dir, 'app'),
        File.join('lib', 'assets', 'javascripts') => File.join(instrumented_dir, 'lib'),
        File.join('public', 'javascripts')        => File.join(instrumented_dir, 'public')
      }
    end
    
    def self.internal_test_exec_file
      File.join output_dir, 'internal_test_executer.html'
    end
  end
end


env = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
if env =~ /^(development|test)$/
  require 'rake' unless self.class.const_defined? :Rake
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

      # Run Jasmine using the original config.
      status_code, shell_buffer = Jasmine::Headless::Runner.run(
          # Any options from the options.rb file in jasmine-headless-webkit can be used here.
          :reporters => [['File', "#{Jasmine::CoverageConfig.output_dir}/rawreport.txt"]]
      )
      
      # print buffered output without base64-encoded coverage information
      puts shell_buffer.gsub(
        /"ENCODED-COVERAGE-EXPORT-STARTS.*ENCODED-COVERAGE-EXPORT-ENDS|\n"\n|jsDump: "/m, '')
      
      if status_code == 1
        puts <<-ERR_NOTE
Test execution finished with an error, which implies one of five things:

1) Your JS files had exactly zero instructions. Are they all blank or just comments?
2) A test failed (open #{Jasmine::CoverageConfig.internal_test_exec_file} with your browser to see which tests are concerned. \
HINT: Use FF, since Chrome has strict security settings that make this difficult; the page accesses the local filesystem from \
Javascript (but you can switch the settings off at the command line))
3) The sourcecode has a syntax error (which JSLint should find)
4) An error occurred in a deferred block, eg a setTimeout or underscore _.defer. This caused a window error which Jasmine will never see.
5) The source files are being loaded out of sequence (so global variables are not being declared in order)
   To check this, run bundle exec jasmine-headless-webkit -l to see the ordering

In any case, try running the standard jasmine-headless-webkit command to get better errors:
  rake jasmine:headless

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
      File.open(File.join(Jasmine::CoverageConfig.output_dir, 'jscoverage.js'), 'a') { |f| f.write("\njscoverage_isReport = true;") }

      if json_report_enc.index("No Javascript was found to test coverage for").nil?
        # Check for coverage failure
        total_location = json_report_enc.index("% Total")
        coverage_pc = json_report_enc[total_location-3, 3].to_i

        conf = (ENV['JSCOVERAGE_MINIMUM'] || ENV['JASMINE_COVERAGE_MINIMUM'])
        fail "Coverage Fail: Javascript coverage was less than #{conf}%. It was #{coverage_pc}%." if conf && coverage_pc < conf.to_i
      end

    end
    
    def add_pathinfo_to_instrumented_js folder, instrumented_dir, folder_orig = folder
      Dir.entries(folder).each do |entry|
        next if entry == '.' || entry == '..'
        if File.directory?(File.join folder, entry) 
          add_pathinfo_to_instrumented_js File.join(folder, entry), File.join(instrumented_dir, entry), folder_orig
        else
          if entry =~ /\.js$/
            instrumented_content= File.read(File.join instrumented_dir, entry)
            instrumented_content.gsub! /_\$jscoverage\['/, "_$jscoverage['#{File.join(folder_orig, '')}"
            File.write File.join(instrumented_dir, entry), instrumented_content
          end
        end
      end
    end
    
    def instrument_js folder, instrumented_dir
      instrument folder, instrumented_dir, 'jscoverage', '-v'
      add_pathinfo_to_instrumented_js folder, instrumented_dir
    end
    
    def instrument_cs folder, instrumented_dir
      instrument folder, instrumented_dir, 'coffeeCoverage', '--verbose --path relative'
    end
    
    def instrument folder, instrumented_dir, exec, option= ''
      return unless File.directory? folder
      
      fail "#{exec} executable not found in PATH" if %x(which #{exec}).empty?

      fail "Instrumenting failed. Error message from system: #{$?}" unless
        system "#{exec} #{option} #{folder} #{instrumented_dir}"
    end
  end
end