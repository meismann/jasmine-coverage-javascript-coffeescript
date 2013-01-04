/**
 * Note, strictly speaking this isn't a spec.
 * But we must run it like one so it occurs in the same context
 * as the other tests that have run. In that way, we can
 * call out in javascript and get the resulting coverage reports from the instrumented
 * files.
 *
 * Further, when we log the results to console, the file logger captures that.
 */
describe("jasmine-coverage", function () {

    it("is generating a coverage report", function () {
        // Output the complete line by line coverage report for capture by the file logger
        generateEncodedCoverage();

        // Get the simple percentages for each file
        coverageForAllFiles();
    });

});

String.prototype.lpad = function (padString, length) {
    var str = this;
    while (str.length < length)
        str = padString + str;
    return str;
};

function generateEncodedCoverage() {
    var rv = {};
    for (var file_name in window._$jscoverage) {
        var jscov = window._$jscoverage[ file_name ];
        var file_report = rv[ file_name ] = {
            coverage:new Array(jscov.length),
            source:new Array(jscov.length)
        };
        for (var i = 0; i < jscov.length; ++i) {
            var hit_count = jscov[ i ] !== undefined ? jscov[ i ] : null;

            file_report.coverage[ i ] = hit_count;
            file_report.source[ i ] = jscov.source[ i ];
        }
    }
    console.log("ENCODED-COVERAGE-EXPORT-STARTS:" + Base64.encode(JSON.stringify(rv)));
    console.log("\nENCODED-COVERAGE-EXPORT-ENDS\n");
}

function coverageForAllFiles() {

    var totals = { files:0, statements:0, executed:0 };

    var output = "Coverage was:\n";

    for (var file_name in window._$jscoverage) {
        var jscov = window._$jscoverage[ file_name ];
        var simple_file_coverage = coverageForFile(jscov);

        totals['files']++;
        totals['statements'] += simple_file_coverage['statements'];
        totals['executed'] += simple_file_coverage['executed'];

        var fraction = (simple_file_coverage['executed']+"/"+simple_file_coverage['statements']).lpad(' ', 10);
        output += fraction + (" = " + simple_file_coverage['percentage'] + "").lpad(' ', 3) + "% for " + file_name + "\n";
    }

    var coverage = parseInt(100 * totals['executed'] / totals['statements']);
    if (isNaN(coverage)) {
        coverage = 0;
    }

    if (totals['statements'] === 0) {
        console.log("No Javascript was found to test coverage for.");
    } else {
        output += ( totals['executed'] +"/"+totals['statements']+ " = "+ coverage + "").lpad(' ', 15) + "% Total\n";
        console.log(output);
    }

    return coverage;
}


function coverageForFile(fileCC) {
    var lineNumber;
    var num_statements = 0;
    var num_executed = 0;
    var missing = [];
    var length = fileCC.length;
    var currentConditionalEnd = 0;
    var conditionals = null;
    if (fileCC.conditionals) {
        conditionals = fileCC.conditionals;
    }
    for (lineNumber = 0; lineNumber < length; lineNumber++) {
        var n = fileCC[lineNumber];

        if (lineNumber === currentConditionalEnd) {
            currentConditionalEnd = 0;
        }
        else if (currentConditionalEnd === 0 && conditionals && conditionals[lineNumber]) {
            currentConditionalEnd = conditionals[lineNumber];
        }

        if (currentConditionalEnd !== 0) {
            continue;
        }

        if (n === undefined || n === null) {
            continue;
        }

        if (n === 0) {
            missing.push(lineNumber);
        }
        else {
            num_executed++;
        }
        num_statements++;
    }

    var percentage = ( num_statements === 0 ? 0 : parseInt(100 * num_executed / num_statements) );

    return {
        statements:num_statements,
        executed:num_executed,
        percentage:percentage
    };
}