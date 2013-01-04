<u>/!\</u> This project is still in its Alpha-phase. It works for me, but may not work for you. Please, kindly report any bugs.

# Jasmine Coverage for Javascript and CoffeeScript

A transcendent blend of useful Java-/CoffeeScript unit testing and colourful coverage graphs.

This gem allows [Jasmine Headless Webkit](http://johnbintz.github.com/jasmine-headless-webkit/)
to be run against a Rails application's Java-/CoffeeScript tests, and then produces a coverage report, optionally failing it if it falls below a configurable level.

Coverage is provided by the [jscoverage](http://siliconforks.com/jscoverage/manual.html) and the [coffeeCoverage](https://github.com/benbria/coffee-coverage) projects.

Credit goes to First Banco, whose tool [jasmine-coverage](https://github.com/firstbanco/jasmine-coverage) this project is derived from.

# Installation

Firstly, ensure you have a binary of [jscoverage](http://siliconforks.com/jscoverage/manual.html)
available on your path. The installation steps are on the webpage. On Mac, you may have to install macports first and then do like `sudo port install jscoverage`. Tested to work with Mountain Lion.

Secondly, ensure you have a binary of [coffeeCoverage](https://github.com/benbria/coffee-coverage)
available on your path. The installation steps are on the page. You may need to install the Node.js Package Manager first (on Mac for example with homebrew: `brew install node`) before you enter the installation process. I recommand to adjust your .bash_profile to add the directory where npm installs binaries to to your PATH; for me this line did the trick:

    export PATH=/usr/local/share/npm/bin:$PATH

Then, add the following in your Gemfile.

    gem 'jasmine-coverage-javascript-coffeescript'

Note, there were a raft of small issues with older versions of [Jasmine Headless Webkit](http://johnbintz.github.com/jasmine-headless-webkit/), so for the moment our project's .gemspec requires at least the current release candidate of that project (>=0.9.0.rc.2).

# Usage

To use jasmine-coverage, run the rake task.

    bundle exec rake jasmine:coverage

Optionally, add a failure level percentage.

    bundle exec rake jasmine:coverage JASMINE_COVERAGE_MINIMUM=75

# Output

You will see the tests execute, then a large blob of text, and finally a summary of the test coverage results.
An HTML file will also be saved that lets you view the results graphically. Apart from Google Chrome, browsers should be able to open this file from a local disk. This is because the jscoverage generated report page needs to make a request for a local json file, and Chrome won't allow a local file to read another local file off disk.

Files generated will be

    coverage/coffee_and_javascript/jscoverage.html  -  The visual report page
    coverage/coffee_and_javascript/jscoverage.json  -  The report data
    coverage/coffee_and_javascript/internal_test_executer.html  -  The actual page that ran the tests (see for failure/success messages)

# How it works

First JSCoverage and coffeeCoverage are told to run over the directories where typically JavaScript and CoffeeScripts are held (i.e. `app/assets/javascripts`, `lib/assets/javascripts`, and `public/javascripts`), and saves the instrumented files. Next, Jasmine Headless Webkit runs as normal, but a couple of monkey patches intercept the locations of the javascript files it expects to find, rerouting them to the instrumented versions.

The data we get from the coverage can only "leave" the JS sandbox one way: via the console. This is why you see such a large block of Base64 encoded rubbish flying past as the build progresses. The console data is captured by Jasmine Coverage, which decodes it and builds the results HTML page, and gives a short summary in the console.

You're done.