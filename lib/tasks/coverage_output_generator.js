var Base64 = {
// private property
_keyStr : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",

// public method for encoding
encode : function (input) {
    var output = "";
    var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
    var i = 0;

    input = Base64._utf8_encode(input);

    while (i < input.length) {

        chr1 = input.charCodeAt(i++);
        chr2 = input.charCodeAt(i++);
        chr3 = input.charCodeAt(i++);

        enc1 = chr1 >> 2;
        enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
        enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
        enc4 = chr3 & 63;

        if (isNaN(chr2)) {
            enc3 = enc4 = 64;
        } else if (isNaN(chr3)) {
            enc4 = 64;
        }

        output = output +
        Base64._keyStr.charAt(enc1) + Base64._keyStr.charAt(enc2) +
        Base64._keyStr.charAt(enc3) + Base64._keyStr.charAt(enc4);

    }

    return output;
},

// public method for decoding
decode : function (input) {
    var output = "";
    var chr1, chr2, chr3;
    var enc1, enc2, enc3, enc4;
    var i = 0;

    input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");

    while (i < input.length) {

        enc1 = Base64._keyStr.indexOf(input.charAt(i++));
        enc2 = Base64._keyStr.indexOf(input.charAt(i++));
        enc3 = Base64._keyStr.indexOf(input.charAt(i++));
        enc4 = Base64._keyStr.indexOf(input.charAt(i++));

        chr1 = (enc1 << 2) | (enc2 >> 4);
        chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
        chr3 = ((enc3 & 3) << 6) | enc4;

        output = output + String.fromCharCode(chr1);

        if (enc3 != 64) {
            output = output + String.fromCharCode(chr2);
        }
        if (enc4 != 64) {
            output = output + String.fromCharCode(chr3);
        }

    }

    output = Base64._utf8_decode(output);

    return output;

},

// private method for UTF-8 encoding
_utf8_encode : function (string) {
    string = string.replace(/\r\n/g,"\n");
    var utftext = "";

    for (var n = 0; n < string.length; n++) {

        var c = string.charCodeAt(n);

        if (c < 128) {
            utftext += String.fromCharCode(c);
        }
        else if((c > 127) && (c < 2048)) {
            utftext += String.fromCharCode((c >> 6) | 192);
            utftext += String.fromCharCode((c & 63) | 128);
        }
        else {
            utftext += String.fromCharCode((c >> 12) | 224);
            utftext += String.fromCharCode(((c >> 6) & 63) | 128);
            utftext += String.fromCharCode((c & 63) | 128);
        }

    }

    return utftext;
},

// private method for UTF-8 decoding
_utf8_decode : function (utftext) {
    var string = "";
    var i = 0;
    var c = c1 = c2 = 0;

    while ( i < utftext.length ) {

        c = utftext.charCodeAt(i);

        if (c < 128) {
            string += String.fromCharCode(c);
            i++;
        }
        else if((c > 191) && (c < 224)) {
            c2 = utftext.charCodeAt(i+1);
            string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
            i += 2;
        }
        else {
            c2 = utftext.charCodeAt(i+1);
            c3 = utftext.charCodeAt(i+2);
            string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
            i += 3;
        }

    }
    return string;
}
}
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
console.log(window._$jscoverage)
    for (var file_name in window._$jscoverage) {
        var jscov = window._$jscoverage[ file_name ];
        var simple_file_coverage = coverageForFile(jscov);

        totals['files']++;
        totals['statements'] += simple_file_coverage['statements'];
        totals['executed'] += simple_file_coverage['executed'];

        var fraction = (simple_file_coverage['executed']+"/"+simple_file_coverage['statements']).lpad(' ', 10);
        output += fraction + " = " + (simple_file_coverage['percentage'] + '').lpad(' ', 3) + "% of " + file_name + "\n";
    }

    var coverage = parseInt(100 * totals['executed'] / totals['statements']);
    if (isNaN(coverage)) {
        coverage = 0;
    }

    if (totals['statements'] === 0) {
        console.log("No Javascript was found to test coverage for.");
    } else {
        output += (totals['executed'] +"/"+totals['statements']).lpad(' ', 10) + " = "+ coverage + "% Total\n";
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

    var percentage = ( num_statements === 0 ? 100 : parseInt(100 * num_executed / num_statements) );

    return {
        statements:num_statements,
        executed:num_executed,
        percentage:percentage
    };
}