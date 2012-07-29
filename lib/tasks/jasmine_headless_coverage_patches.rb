# This file holds the monkeypatches to open up jasmine headless for jasmine coverage.


# This patch writes out a copy of the file that was loaded into the JSCoverage context for testing.
# You can look at it to see if it included all the files and tests you expect.
require 'jasmine/headless/template_writer'
module Jasmine::Headless
  class TemplateWriter
    alias old_write :write

    def write
      ret = old_write
      file = Jasmine::Coverage.output_dir+"/jscoverage-test-rig.html"
      FileUtils.cp(all_tests_filename, file)
      puts "A copy of the complete page that was used as the test environment can be found here:"
      puts "#{file}"
      ret
    end
  end
end

# Here we patch the resource handler to output the location of our instrumented files
module Jasmine::Headless
  class FilesList

    alias old_to_html :to_html

    def to_html(files)
      # Declare our test runner files
      cov_files = ['/jscoverage.js', '/coverage_output_generator.js']

      # Add the original files, remapping to instrumented where necessary
      tags = []
      (old_to_html files).each do |path|
        files_map = Jasmine::Coverage.resources
        files_map.keys.each do |folder|
          path = path.sub(folder, files_map[folder])

          # Here we must check the supplied config hasn't pulled in our jscoverage runner file.
          # If it has, the tests will fire too early, capturing only minimal coverage
          if cov_files.select { |f| path.include?(f) }.length > 0
            fail "Assets defined by jasmine.yml must not include any of #{cov_files}: #{path}"
          end

        end
        tags << path
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
end