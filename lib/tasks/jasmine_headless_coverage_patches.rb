# This file holds the monkeypatches to open up jasmine-headless-webkit for jasmine coverage.

# This patch writes out a copy of the file that was loaded into the JSCoverage context for testing.
# You can look at it to see if it included all the files and tests you expect.
require 'jasmine/headless/template_writer'
module Jasmine::Headless
  class TemplateWriter
    alias old_write :write

    def write
      ret = old_write

      # Make a dump of the file that was used for non-browser test execution
      File.delete(Jasmine::CoverageConfig.internal_test_exec_file) if File.exists? Jasmine::CoverageConfig.internal_test_exec_file
      FileUtils.cp all_tests_filename, Jasmine::CoverageConfig.internal_test_exec_file
      puts "A copy of the complete page that was used as the test environment can be found here (for off-browser testing):"
      puts Jasmine::CoverageConfig.internal_test_exec_file

      ret
    end
  end

# Here we patch the resource handler to output the location of our instrumented files
  class FilesList

    alias old_to_html :to_html

    def to_html(files)
      # Declare our test runner files
      cov_files = ['/jscoverage.js', '/coverage_output_generator.js']

      # Add the original files, remapping to instrumented where necessary
      tags = []
      (old_to_html files).each do |path|
        # Remove the .jhw-cache/coffee_script part of the path, so the file will get correctly
        # replaced with its instrumented version
        if !(path =~ /\/gems\// ) &&
            path =~ /\/\.jhw-cache\/[^']+\/[^\/]+\.coffee/ &&
          !(path =~ /\/.jhw-cache\/coffee_script\/spec\/javascripts\//)
          path.gsub! '.jhw-cache/coffee_script/', ''
        end

        Jasmine::CoverageConfig.files_map.keys.each do |folder|
          path = path.sub(folder, Jasmine::CoverageConfig.files_map[folder])

          # Here we must check the supplied config hasn't pulled in our jscoverage runner file.
          # If it has, the tests will fire too early, capturing only minimal coverage
          if cov_files.select { |f| path.include?(f) }.length > 0
            fail "Assets defined by jasmine.yml must not include any of #{cov_files}: #{path}"
          end

        end
        tags << path

        # The instrumented coffeescript files placed in the instrumented/* directories are expected
        # to end in .coffee.js, but they really end in .js. Adjust path accordingly:
        path.sub! /(.+\/instrumented\/.+)\.coffee/, %q(\1)
        
      end

      # Attach the "in context" test runners
      tags = tags + old_to_html(cov_files.map { |f| File.dirname(__FILE__)+f })

      tags
    end

    alias old_sprockets_environment :sprockets_environment

    def sprockets_environment
      return @sprockets_environment if @sprockets_environment
      old_sprockets_environment
      # Add the location of our jscoverage.js
      @sprockets_environment.append_path(File.dirname(__FILE__))
      @sprockets_environment
    end
  end
  
  class Runner
    
    alias old_run :run
    
    def run
      shell_buffer = nil
      self.class.send :define_method, :system do |command|
        shell_buffer = %x(#{command})
      end
      [old_run, shell_buffer]
    ensure
      self.class.send :remove_method, :system
    end
    
  end
end
