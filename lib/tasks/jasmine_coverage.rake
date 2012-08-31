env = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
if env =~ /^(development|test)$/
  require 'rake'
  require 'base64'

  namespace :jasmine do
    desc 'Runs jasmine with a coverage report'
    task :coverage do

      require 'jasmine-headless-webkit'
      # Instill our patches for jasmine-headless to work
      require_relative 'jasmine_headless_coverage_patches'

      # We use jasmine-headless-webkit, since it has excellent programmatic integration with Jasmine
      # But... the 'headless' part of it doesn't work on TeamCity, so we use the headless gem
      require 'headless'

      headless = Headless.new
      headless.start

      # Preprocess the JS files to add instrumentation
      output_dir = File.expand_path('target/jscoverage/')
      instrumented_dir = output_dir+'/instrumented/'
      FileUtils.rm_rf output_dir
      FileUtils.mkdir_p instrumented_dir

      # The reprocessing folder map
      files_map = {
          File.expand_path('app/assets/javascripts') => instrumented_dir+'app',
          File.expand_path('lib/assets/javascripts') => instrumented_dir+'lib',
          File.expand_path('public/javascripts') => instrumented_dir+'public'
      }

      # Instrument the source files into the instrumented folders
      files_map.keys.each do |folder|
        instrument(folder, files_map[folder])
        # Also hoist up the eventual viewing files
        FileUtils.mv(Dir.glob(files_map[folder]+'/jscoverage*'), output_dir)
      end

      Jasmine::Coverage.resources = files_map
      Jasmine::Coverage.output_dir = output_dir

      puts "\nCoverage will now be run. Expect a large block of compiled coverage data. This will be processed for you into target/jscoverage.\n\n"

      # Run Jasmine using the original config.
      status_code = Jasmine::Headless::Runner.run(
          # Any options from the options.rb file in jasmine-headless-webkit can be used here.

          :reporters => [['File', "#{output_dir}/rawreport.txt"]]
      )
      errStr = "JSCoverage exited with error code: #{status_code}.\nThis implies one of four things:\n"
      errStr = errStr +"0) Your JS files had exactly zero instructions. Are they all blank or just comments?\n"
      errStr = errStr +"1) A test failed (run bundle exec jasmine:headless to see a better error)\n"
      errStr = errStr +"2) The sourcecode has a syntax error (which JSLint should find)\n"
      errStr = errStr +"3) The source files are being loaded out of sequence (so global variables are not being declared in order)\n"
      errStr = errStr +"   To check this, run bundle exec jasmine-headless-webkit -l to see the ordering\n"
      errStr = errStr +"\nIn any case, try running the standard jasmine command to get better errors:\n\nbundle exec jasmine:headless\n\n"
      errStr = errStr +"\nFinally, try opening the testrig in firefox to see the tests run in a browser and get a stacktrace.\n"
      errStr = errStr +"\nChrome has strict security settings that make this difficult since it accesses the local filesystem from Javascript (but you can switch the settings off at the command line)\n\n"
      errStr = errStr +"\ntarget/jscoverage/testrig/jscoverage-test-rig.html\n\n"
      fail errStr if status_code == 1

      # Obtain the console log, which includes the coverage report encoded within it
      contents = File.open("#{output_dir}/rawreport.txt") { |f| f.read }
      # Get our Base64.
      json_report_enc = contents.split(/ENCODED-COVERAGE-EXPORT-STARTS:/m)[1]
      # Remove the junk at the end
      json_report_enc_stripped = json_report_enc[0, json_report_enc.index("\"")]

      # Unpack it from Base64
      json_report = Base64.decode64(json_report_enc_stripped)

      # Save the coverage report where the GUI html expects it to be
      File.open("#{output_dir}/jscoverage.json", 'w') { |f| f.write(json_report) }

      # Modify the jscoverage.html so it knows it is showing a report, not running a test
      File.open("#{output_dir}/jscoverage.js", 'a') { |f| f.write("\njscoverage_isReport = true;") }

      if json_report_enc.index("No Javascript was found to test coverage for").nil?
        # Check for coverage failure
        total_location = json_report_enc.index("% Total")
        coverage_pc = json_report_enc[total_location-3, 3].to_i

        conf = (ENV['JSCOVERAGE_MINIMUM'] || ENV['JASMINE_COVERAGE_MINIMUM'])
        fail "Coverage Fail: Javascript coverage was less than #{conf}%. It was #{coverage_pc}%." if conf && coverage_pc < conf.to_i
      end

    end

    def instrument folder, instrumented_sub_dir
      return if !File.directory? folder
      FileUtils.mkdir_p instrumented_sub_dir
      puts "Locating jscoverage..."
      system "which jscoverage"
      puts "Instrumenting JS files..."
      jsc_status = system "jscoverage -v #{folder} #{instrumented_sub_dir}"
      if jsc_status != true
        puts "jscoverage failed with status '#{jsc_status}'. Is jscoverage on your path? Path follows:"
        system "echo $PATH"
        puts "Result of calling jscoverage with no arguments follows:"
        system "jscoverage"
        fail "Unable to use jscoverage"
      end
    end
  end

  module Jasmine
    module Coverage
      @resources

      def self.resources= resources
        @resources = resources
      end

      def self.resources
        @resources
      end

      @output_dir

      def self.output_dir= output_dir
        @output_dir = output_dir
      end

      def self.output_dir
        @output_dir
      end
    end
  end

end