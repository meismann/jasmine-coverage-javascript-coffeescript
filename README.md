/!\\ This project is still in its Beta-phase. It works for a whole bunch of happy users, but may not work for you. Please, kindly report any bugs.

# JCJC - A Test Coverage Visualiser for Javascript and CoffeeScript with Jasmine

Jasmine-Coverage-JavaScript-CoffeeScript (JCJC) is transcendent blend of useful Java-/CoffeeScript unit testing and colourful coverage graphs.

This gem allows [Jasmine Headless Webkit](http://johnbintz.github.com/jasmine-headless-webkit/)
to be run against a Rails application's Java-/CoffeeScript tests, and then produces a coverage report, optionally failing it if it falls below a configurable level.

Coverage is provided by the [jscoverage](http://siliconforks.com/jscoverage/manual.html) and the [coffeeCoverage](https://github.com/benbria/coffee-coverage) projects.

Credit goes to First Banco, whose tool [jasmine-coverage](https://github.com/firstbanco/jasmine-coverage) this project is derived from.

## Installation

### 1 Ensure you have a binary of [jscoverage](http://siliconforks.com/jscoverage/manual.html) available on your path.
The installation steps are on the webpage. On Mac, you may have to install [macports](http://www.macports.org/install.php) first and then do `sudo port install jscoverage`. Tested to work with Mountain Lion.

Do not forget to run `source ~/.bash_profile` to get the updated $PATH available to your shell, which should now contain a directory where Macports puts executables.  

### 2 Ensure you have a binary of [coffeeCoverage](https://github.com/benbria/coffee-coverage) available on your path.
The installation steps are on the page. Some hints: you may need to install the Node.js Package Manager first (on Mac for example with homebrew: `brew install node`) before you enter the installation process. If you are on Mac and homebrew installs node without npm (see console output!), follow the steps indicated to install it separately (probably suggesting to do `curl https://npmjs.org/install.sh`). Now you can run the installation of coffeeCoverage with npm.

Type `coffeeCoverage` and check whether the command is known by your shell. If so, jump to point three, otherwise I recommand to adjust your .bash_profile to add the directory where npm installs binaries to to your PATH; for me this line did the trick:

    export PATH=/usr/local/share/npm/bin:$PATH
    
Do not forget to run `source ~/.bash_profile` to get the updated $PATH available to your shell, which should now contain a directory where NPM puts executables. Then typing `coffeeCoverage` should produce an error message directly coming from coffeeCoverage.  

### 3 You need the Qt library in order to later install [Jasmine Headless Webkit](http://johnbintz.github.com/jasmine-headless-webkit/) correctly.
jasmine-headless-webkit is a dependency of JCJC and gets installed when bundler installs JCJC. During installation, Qt is necessary. To install it on a Mac with homebrew, you would simply do `brew install qt`. You can visit [their website](http://johnbintz.github.com/jasmine-headless-webkit/) to check out how to do install Qt on other operating systems.

Then, add the following in your Gemfile.

    gem 'jasmine-coverage-javascript-coffeescript'
    
and run
  
    bundle install

If you had not previously installed Qt, running `bundle install` would not show you any error, however, you could not run the test suite with `rake jasmine:headless`, for this would just as well fail without any error message. Note, there were a raft of small issues with older versions of Jasmine Headless Webkit, so for the moment our project's .gemspec requires at least the current release candidate of that project (>=0.9.0.rc.2).

## Usage

To use jasmine-coverage-javascript-coffeescript, run the rake task (may work without `bundle exec` depending on your Gem collection environment):

    bundle exec rake jasmine:coverage

Optionally, add a failure level percentage.

    bundle exec rake jasmine:coverage JASMINE_COVERAGE_MINIMUM=75
    
If you have not been previously using Jasmine Headless Webkit already, it may be of interest that you can now run your whole test suite without a browser, simply on the command line, with:

    bundle exec rake jasmine:headless

## Output

You will see the tests execute, then a large blob of text, and finally a summary of the test coverage results.
An HTML file will also be saved that lets you view the results graphically. Apart from Google Chrome, browsers should be able to open this file from a local disk. This is because the jscoverage generated report page needs to make a request for a local json file, and Chrome won't allow a local file to read another local file off disk.

Files generated will be

    coverage/coffee_and_javascript/jscoverage.html  -  The visual report page
    coverage/coffee_and_javascript/jscoverage.json  -  The report data
    coverage/coffee_and_javascript/internal_test_executer.html  -  The actual page that ran the tests (see for failure/success messages)

## How it works

First JSCoverage and coffeeCoverage are told to run over the directories where typically JavaScript and CoffeeScripts are held (i.e. `app/assets/javascripts`, `lib/assets/javascripts`, and `public/javascripts`), and saves the instrumented files. Next, Jasmine Headless Webkit runs as normal, but a couple of monkey patches intercept the locations of the javascript files it expects to find, rerouting them to the instrumented versions.

The data we get from the coverage can only "leave" the JS sandbox one way: via the console. This is why you see such a large block of Base64 encoded rubbish flying past as the build progresses. The console data is captured by Jasmine Coverage, which decodes it and builds the results HTML page, and gives a short summary in the console.

## Troubleshooting

**`rake jasmine:coverage` aborts with announcing that Javascript assets provided by a gem and required in a manifest cannot be found.**<br>
Did you install the gem [jasminrice](https://github.com/bradphelan/jasminerice)? If so, did you follow their installing instructions by executing

    rails g jasminerice:install
    
**`rake jasmine:coverage` aborts with announcing that Javascript assets from within your own app and required in a manifest cannot be found.**<br>
Make sure your `spec/javascript/support/jasmine.yml` contains a key `src_dir`, which lists the directory where the missing asset is located, like so:

    src_dir:
      - app/assets/javascripts
      - lib/assets/javascripts
      - vendor/assets/javascripts
  

**Your specs do not find the code under test.**<br>
If you have previously installed `jasminerice`, make sure you have followed their installing instructions, which should have created a file `spec/javascript/spec.js.coffee`. Make sure, it requires the files with the code under test, like so:

    #= require_tree ./ 
    #= require_tree ../../app/assets/javascripts

**`rake jasmine:coverage` aborts without failure message**<br>
You probably missed the Qt part in the installation section. Install Qt. If you have installed Qt and the problem persists, you have probably installed Qt only after you had installed the jasmine-headless-webkit gem. In this cas run `gem uninstall jasmine-headless-webkit`, confirm the prompts, and then run `bundle install` again to re-install the gem. Background: the executables necessary to run the tests headlessly with this gem are only compiled at installation time, at which Qt has to be around and available already.
