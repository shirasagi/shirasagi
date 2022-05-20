//! moment.js
//! version : 2.20.1
//! authors : Tim Wood, Iskren Chernev, Moment.js contributors
//! license : MIT
//! momentjs.com

;(function (global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
    typeof define === 'function' && define.amd ? define(factory) :
    global.moment = factory()
}(this, (function () { 'use strict';

var hookCallback;

function hooks () {
    return hookCallback.apply(null, arguments);
}

// This is done to register the method called with moment()
// without creating circular dependencies.
function setHookCallback (callback) {
    hookCallback = callback;
}

function isArray(input) {
    return input instanceof Array || Object.prototype.toString.call(input) === '[object Array]';
}

function isObject(input) {
    // IE8 will treat undefined and null as object if it wasn't for
    // input != null
    return input != null && Object.prototype.toString.call(input) === '[object Object]';
}

function isObjectEmpty(obj) {
    if (Object.getOwnPropertyNames) {
        return (Object.getOwnPropertyNames(obj).length === 0);
    } else {
        var k;
        for (k in obj) {
            if (obj.hasOwnProperty(k)) {
                return false;
            }
        }
        return true;
    }
}

function isUndefined(input) {
    return input === void 0;
}

function isNumber(input) {
    return typeof input === 'number' || Object.prototype.toString.call(input) === '[object Number]';
}

function isDate(input) {
    return input instanceof Date || Object.prototype.toString.call(input) === '[object Date]';
}

function map(arr, fn) {
    var res = [], i;
    for (i = 0; i < arr.length; ++i) {
        res.push(fn(arr[i], i));
    }
    return res;
}

function hasOwnProp(a, b) {
    return Object.prototype.hasOwnProperty.call(a, b);
}

function extend(a, b) {
    for (var i in b) {
        if (hasOwnProp(b, i)) {
            a[i] = b[i];
        }
    }

    if (hasOwnProp(b, 'toString')) {
        a.toString = b.toString;
    }

    if (hasOwnProp(b, 'valueOf')) {
        a.valueOf = b.valueOf;
    }

    return a;
}

function createUTC (input, format, locale, strict) {
    return createLocalOrUTC(input, format, locale, strict, true).utc();
}

function defaultParsingFlags() {
    // We need to deep clone this object.
    return {
        empty           : false,
        unusedTokens    : [],
        unusedInput     : [],
        overflow        : -2,
        charsLeftOver   : 0,
        nullInput       : false,
        invalidMonth    : null,
        invalidFormat   : false,
        userInvalidated : false,
        iso             : false,
        parsedDateParts : [],
        meridiem        : null,
        rfc2822         : false,
        weekdayMismatch : false
    };
}

function getParsingFlags(m) {
    if (m._pf == null) {
        m._pf = defaultParsingFlags();
    }
    return m._pf;
}

var some;
if (Array.prototype.some) {
    some = Array.prototype.some;
} else {
    some = function (fun) {
        var t = Object(this);
        var len = t.length >>> 0;

        for (var i = 0; i < len; i++) {
            if (i in t && fun.call(this, t[i], i, t)) {
                return true;
            }
        }

        return false;
    };
}

function isValid(m) {
    if (m._isValid == null) {
        var flags = getParsingFlags(m);
        var parsedParts = some.call(flags.parsedDateParts, function (i) {
            return i != null;
        });
        var isNowValid = !isNaN(m._d.getTime()) &&
            flags.overflow < 0 &&
            !flags.empty &&
            !flags.invalidMonth &&
            !flags.invalidWeekday &&
            !flags.weekdayMismatch &&
            !flags.nullInput &&
            !flags.invalidFormat &&
            !flags.userInvalidated &&
            (!flags.meridiem || (flags.meridiem && parsedParts));

        if (m._strict) {
            isNowValid = isNowValid &&
                flags.charsLeftOver === 0 &&
                flags.unusedTokens.length === 0 &&
                flags.bigHour === undefined;
        }

        if (Object.isFrozen == null || !Object.isFrozen(m)) {
            m._isValid = isNowValid;
        }
        else {
            return isNowValid;
        }
    }
    return m._isValid;
}

function createInvalid (flags) {
    var m = createUTC(NaN);
    if (flags != null) {
        extend(getParsingFlags(m), flags);
    }
    else {
        getParsingFlags(m).userInvalidated = true;
    }

    return m;
}

// Plugins that add properties should also add the key here (null value),
// so we can properly clone ourselves.
var momentProperties = hooks.momentProperties = [];

function copyConfig(to, from) {
    var i, prop, val;

    if (!isUndefined(from._isAMomentObject)) {
        to._isAMomentObject = from._isAMomentObject;
    }
    if (!isUndefined(from._i)) {
        to._i = from._i;
    }
    if (!isUndefined(from._f)) {
        to._f = from._f;
    }
    if (!isUndefined(from._l)) {
        to._l = from._l;
    }
    if (!isUndefined(from._strict)) {
        to._strict = from._strict;
    }
    if (!isUndefined(from._tzm)) {
        to._tzm = from._tzm;
    }
    if (!isUndefined(from._isUTC)) {
        to._isUTC = from._isUTC;
    }
    if (!isUndefined(from._offset)) {
        to._offset = from._offset;
    }
    if (!isUndefined(from._pf)) {
        to._pf = getParsingFlags(from);
    }
    if (!isUndefined(from._locale)) {
        to._locale = from._locale;
    }

    if (momentProperties.length > 0) {
        for (i = 0; i < momentProperties.length; i++) {
            prop = momentProperties[i];
            val = from[prop];
            if (!isUndefined(val)) {
                to[prop] = val;
            }
        }
    }

    return to;
}

var updateInProgress = false;

// Moment prototype object
function Moment(config) {
    copyConfig(this, config);
    this._d = new Date(config._d != null ? config._d.getTime() : NaN);
    if (!this.isValid()) {
        this._d = new Date(NaN);
    }
    // Prevent infinite loop in case updateOffset creates new moment
    // objects.
    if (updateInProgress === false) {
        updateInProgress = true;
        hooks.updateOffset(this);
        updateInProgress = false;
    }
}

function isMoment (obj) {
    return obj instanceof Moment || (obj != null && obj._isAMomentObject != null);
}

function absFloor (number) {
    if (number < 0) {
        // -0 -> 0
        return Math.ceil(number) || 0;
    } else {
        return Math.floor(number);
    }
}

function toInt(argumentForCoercion) {
    var coercedNumber = +argumentForCoercion,
        value = 0;

    if (coercedNumber !== 0 && isFinite(coercedNumber)) {
        value = absFloor(coercedNumber);
    }

    return value;
}

// compare two arrays, return the number of differences
function compareArrays(array1, array2, dontConvert) {
    var len = Math.min(array1.length, array2.length),
        lengthDiff = Math.abs(array1.length - array2.length),
        diffs = 0,
        i;
    for (i = 0; i < len; i++) {
        if ((dontConvert && array1[i] !== array2[i]) ||
            (!dontConvert && toInt(array1[i]) !== toInt(array2[i]))) {
            diffs++;
        }
    }
    return diffs + lengthDiff;
}

function warn(msg) {
    if (hooks.suppressDeprecationWarnings === false &&
            (typeof console !==  'undefined') && console.warn) {
        console.warn('Deprecation warning: ' + msg);
    }
}

function deprecate(msg, fn) {
    var firstTime = true;

    return extend(function () {
        if (hooks.deprecationHandler != null) {
            hooks.deprecationHandler(null, msg);
        }
        if (firstTime) {
            var args = [];
            var arg;
            for (var i = 0; i < arguments.length; i++) {
                arg = '';
                if (typeof arguments[i] === 'object') {
                    arg += '\n[' + i + '] ';
                    for (var key in arguments[0]) {
                        arg += key + ': ' + arguments[0][key] + ', ';
                    }
                    arg = arg.slice(0, -2); // Remove trailing comma and space
                } else {
                    arg = arguments[i];
                }
                args.push(arg);
            }
            warn(msg + '\nArguments: ' + Array.prototype.slice.call(args).join('') + '\n' + (new Error()).stack);
            firstTime = false;
        }
        return fn.apply(this, arguments);
    }, fn);
}

var deprecations = {};

function deprecateSimple(name, msg) {
    if (hooks.deprecationHandler != null) {
        hooks.deprecationHandler(name, msg);
    }
    if (!deprecations[name]) {
        warn(msg);
        deprecations[name] = true;
    }
}

hooks.suppressDeprecationWarnings = false;
hooks.deprecationHandler = null;

function isFunction(input) {
    return input instanceof Function || Object.prototype.toString.call(input) === '[object Function]';
}

function set (config) {
    var prop, i;
    for (i in config) {
        prop = config[i];
        if (isFunction(prop)) {
            this[i] = prop;
        } else {
            this['_' + i] = prop;
        }
    }
    this._config = config;
    // Lenient ordinal parsing accepts just a number in addition to
    // number + (possibly) stuff coming from _dayOfMonthOrdinalParse.
    // TODO: Remove "ordinalParse" fallback in next major release.
    this._dayOfMonthOrdinalParseLenient = new RegExp(
        (this._dayOfMonthOrdinalParse.source || this._ordinalParse.source) +
            '|' + (/\d{1,2}/).source);
}

function mergeConfigs(parentConfig, childConfig) {
    var res = extend({}, parentConfig), prop;
    for (prop in childConfig) {
        if (hasOwnProp(childConfig, prop)) {
            if (isObject(parentConfig[prop]) && isObject(childConfig[prop])) {
                res[prop] = {};
                extend(res[prop], parentConfig[prop]);
                extend(res[prop], childConfig[prop]);
            } else if (childConfig[prop] != null) {
                res[prop] = childConfig[prop];
            } else {
                delete res[prop];
            }
        }
    }
    for (prop in parentConfig) {
        if (hasOwnProp(parentConfig, prop) &&
                !hasOwnProp(childConfig, prop) &&
                isObject(parentConfig[prop])) {
            // make sure changes to properties don't modify parent config
            res[prop] = extend({}, res[prop]);
        }
    }
    return res;
}

function Locale(config) {
    if (config != null) {
        this.set(config);
    }
}

var keys;

if (Object.keys) {
    keys = Object.keys;
} else {
    keys = function (obj) {
        var i, res = [];
        for (i in obj) {
            if (hasOwnProp(obj, i)) {
                res.push(i);
            }
        }
        return res;
    };
}

var defaultCalendar = {
    sameDay : '[Today at] LT',
    nextDay : '[Tomorrow at] LT',
    nextWeek : 'dddd [at] LT',
    lastDay : '[Yesterday at] LT',
    lastWeek : '[Last] dddd [at] LT',
    sameElse : 'L'
};

function calendar (key, mom, now) {
    var output = this._calendar[key] || this._calendar['sameElse'];
    return isFunction(output) ? output.call(mom, now) : output;
}

var defaultLongDateFormat = {
    LTS  : 'h:mm:ss A',
    LT   : 'h:mm A',
    L    : 'MM/DD/YYYY',
    LL   : 'MMMM D, YYYY',
    LLL  : 'MMMM D, YYYY h:mm A',
    LLLL : 'dddd, MMMM D, YYYY h:mm A'
};

function longDateFormat (key) {
    var format = this._longDateFormat[key],
        formatUpper = this._longDateFormat[key.toUpperCase()];

    if (format || !formatUpper) {
        return format;
    }

    this._longDateFormat[key] = formatUpper.replace(/MMMM|MM|DD|dddd/g, function (val) {
        return val.slice(1);
    });

    return this._longDateFormat[key];
}

var defaultInvalidDate = 'Invalid date';

function invalidDate () {
    return this._invalidDate;
}

var defaultOrdinal = '%d';
var defaultDayOfMonthOrdinalParse = /\d{1,2}/;

function ordinal (number) {
    return this._ordinal.replace('%d', number);
}

var defaultRelativeTime = {
    future : 'in %s',
    past   : '%s ago',
    s  : 'a few seconds',
    ss : '%d seconds',
    m  : 'a minute',
    mm : '%d minutes',
    h  : 'an hour',
    hh : '%d hours',
    d  : 'a day',
    dd : '%d days',
    M  : 'a month',
    MM : '%d months',
    y  : 'a year',
    yy : '%d years'
};

function relativeTime (number, withoutSuffix, string, isFuture) {
    var output = this._relativeTime[string];
    return (isFunction(output)) ?
        output(number, withoutSuffix, string, isFuture) :
        output.replace(/%d/i, number);
}

function pastFuture (diff, output) {
    var format = this._relativeTime[diff > 0 ? 'future' : 'past'];
    return isFunction(format) ? format(output) : format.replace(/%s/i, output);
}

var aliases = {};

function addUnitAlias (unit, shorthand) {
    var lowerCase = unit.toLowerCase();
    aliases[lowerCase] = aliases[lowerCase + 's'] = aliases[shorthand] = unit;
}

function normalizeUnits(units) {
    return typeof units === 'string' ? aliases[units] || aliases[units.toLowerCase()] : undefined;
}

function normalizeObjectUnits(inputObject) {
    var normalizedInput = {},
        normalizedProp,
        prop;

    for (prop in inputObject) {
        if (hasOwnProp(inputObject, prop)) {
            normalizedProp = normalizeUnits(prop);
            if (normalizedProp) {
                normalizedInput[normalizedProp] = inputObject[prop];
            }
        }
    }

    return normalizedInput;
}

var priorities = {};

function addUnitPriority(unit, priority) {
    priorities[unit] = priority;
}

function getPrioritizedUnits(unitsObj) {
    var units = [];
    for (var u in unitsObj) {
        units.push({unit: u, priority: priorities[u]});
    }
    units.sort(function (a, b) {
        return a.priority - b.priority;
    });
    return units;
}

function zeroFill(number, targetLength, forceSign) {
    var absNumber = '' + Math.abs(number),
        zerosToFill = targetLength - absNumber.length,
        sign = number >= 0;
    return (sign ? (forceSign ? '+' : '') : '-') +
        Math.pow(10, Math.max(0, zerosToFill)).toString().substr(1) + absNumber;
}

var formattingTokens = /(\[[^\[]*\])|(\\)?([Hh]mm(ss)?|Mo|MM?M?M?|Do|DDDo|DD?D?D?|ddd?d?|do?|w[o|w]?|W[o|W]?|Qo?|YYYYYY|YYYYY|YYYY|YY|gg(ggg?)?|GG(GGG?)?|e|E|a|A|hh?|HH?|kk?|mm?|ss?|S{1,9}|x|X|zz?|ZZ?|.)/g;

var localFormattingTokens = /(\[[^\[]*\])|(\\)?(LTS|LT|LL?L?L?|l{1,4})/g;

var formatFunctions = {};

var formatTokenFunctions = {};

// token:    'M'
// padded:   ['MM', 2]
// ordinal:  'Mo'
// callback: function () { this.month() + 1 }
function addFormatToken (token, padded, ordinal, callback) {
    var func = callback;
    if (typeof callback === 'string') {
        func = function () {
            return this[callback]();
        };
    }
    if (token) {
        formatTokenFunctions[token] = func;
    }
    if (padded) {
        formatTokenFunctions[padded[0]] = function () {
            return zeroFill(func.apply(this, arguments), padded[1], padded[2]);
        };
    }
    if (ordinal) {
        formatTokenFunctions[ordinal] = function () {
            return this.localeData().ordinal(func.apply(this, arguments), token);
        };
    }
}

function removeFormattingTokens(input) {
    if (input.match(/\[[\s\S]/)) {
        return input.replace(/^\[|\]$/g, '');
    }
    return input.replace(/\\/g, '');
}

function makeFormatFunction(format) {
    var array = format.match(formattingTokens), i, length;

    for (i = 0, length = array.length; i < length; i++) {
        if (formatTokenFunctions[array[i]]) {
            array[i] = formatTokenFunctions[array[i]];
        } else {
            array[i] = removeFormattingTokens(array[i]);
        }
    }

    return function (mom) {
        var output = '', i;
        for (i = 0; i < length; i++) {
            output += isFunction(array[i]) ? array[i].call(mom, format) : array[i];
        }
        return output;
    };
}

// format date using native date object
function formatMoment(m, format) {
    if (!m.isValid()) {
        return m.localeData().invalidDate();
    }

    format = expandFormat(format, m.localeData());
    formatFunctions[format] = formatFunctions[format] || makeFormatFunction(format);

    return formatFunctions[format](m);
}

function expandFormat(format, locale) {
    var i = 5;

    function replaceLongDateFormatTokens(input) {
        return locale.longDateFormat(input) || input;
    }

    localFormattingTokens.lastIndex = 0;
    while (i >= 0 && localFormattingTokens.test(format)) {
        format = format.replace(localFormattingTokens, replaceLongDateFormatTokens);
        localFormattingTokens.lastIndex = 0;
        i -= 1;
    }

    return format;
}

var match1         = /\d/;            //       0 - 9
var match2         = /\d\d/;          //      00 - 99
var match3         = /\d{3}/;         //     000 - 999
var match4         = /\d{4}/;         //    0000 - 9999
var match6         = /[+-]?\d{6}/;    // -999999 - 999999
var match1to2      = /\d\d?/;         //       0 - 99
var match3to4      = /\d\d\d\d?/;     //     999 - 9999
var match5to6      = /\d\d\d\d\d\d?/; //   99999 - 999999
var match1to3      = /\d{1,3}/;       //       0 - 999
var match1to4      = /\d{1,4}/;       //       0 - 9999
var match1to6      = /[+-]?\d{1,6}/;  // -999999 - 999999

var matchUnsigned  = /\d+/;           //       0 - inf
var matchSigned    = /[+-]?\d+/;      //    -inf - inf

var matchOffset    = /Z|[+-]\d\d:?\d\d/gi; // +00:00 -00:00 +0000 -0000 or Z
var matchShortOffset = /Z|[+-]\d\d(?::?\d\d)?/gi; // +00 -00 +00:00 -00:00 +0000 -0000 or Z

var matchTimestamp = /[+-]?\d+(\.\d{1,3})?/; // 123456789 123456789.123

// any word (or two) characters or numbers including two/three word month in arabic.
// includes scottish gaelic two word and hyphenated months
var matchWord = /[0-9]{0,256}['a-z\u00A0-\u05FF\u0700-\uD7FF\uF900-\uFDCF\uFDF0-\uFF07\uFF10-\uFFEF]{1,256}|[\u0600-\u06FF\/]{1,256}(\s*?[\u0600-\u06FF]{1,256}){1,2}/i;


var regexes = {};

function addRegexToken (token, regex, strictRegex) {
    regexes[token] = isFunction(regex) ? regex : function (isStrict, localeData) {
        return (isStrict && strictRegex) ? strictRegex : regex;
    };
}

function getParseRegexForToken (token, config) {
    if (!hasOwnProp(regexes, token)) {
        return new RegExp(unescapeFormat(token));
    }

    return regexes[token](config._strict, config._locale);
}

// Code from http://stackoverflow.com/questions/3561493/is-there-a-regexp-escape-function-in-javascript
function unescapeFormat(s) {
    return regexEscape(s.replace('\\', '').replace(/\\(\[)|\\(\])|\[([^\]\[]*)\]|\\(.)/g, function (matched, p1, p2, p3, p4) {
        return p1 || p2 || p3 || p4;
    }));
}

function regexEscape(s) {
    return s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
}

var tokens = {};

function addParseToken (token, callback) {
    var i, func = callback;
    if (typeof token === 'string') {
        token = [token];
    }
    if (isNumber(callback)) {
        func = function (input, array) {
            array[callback] = toInt(input);
        };
    }
    for (i = 0; i < token.length; i++) {
        tokens[token[i]] = func;
    }
}

function addWeekParseToken (token, callback) {
    addParseToken(token, function (input, array, config, token) {
        config._w = config._w || {};
        callback(input, config._w, config, token);
    });
}

function addTimeToArrayFromToken(token, input, config) {
    if (input != null && hasOwnProp(tokens, token)) {
        tokens[token](input, config._a, config, token);
    }
}

var YEAR = 0;
var MONTH = 1;
var DATE = 2;
var HOUR = 3;
var MINUTE = 4;
var SECOND = 5;
var MILLISECOND = 6;
var WEEK = 7;
var WEEKDAY = 8;

// FORMATTING

addFormatToken('Y', 0, 0, function () {
    var y = this.year();
    return y <= 9999 ? '' + y : '+' + y;
});

addFormatToken(0, ['YY', 2], 0, function () {
    return this.year() % 100;
});

addFormatToken(0, ['YYYY',   4],       0, 'year');
addFormatToken(0, ['YYYYY',  5],       0, 'year');
addFormatToken(0, ['YYYYYY', 6, true], 0, 'year');

// ALIASES

addUnitAlias('year', 'y');

// PRIORITIES

addUnitPriority('year', 1);

// PARSING

addRegexToken('Y',      matchSigned);
addRegexToken('YY',     match1to2, match2);
addRegexToken('YYYY',   match1to4, match4);
addRegexToken('YYYYY',  match1to6, match6);
addRegexToken('YYYYYY', match1to6, match6);

addParseToken(['YYYYY', 'YYYYYY'], YEAR);
addParseToken('YYYY', function (input, array) {
    array[YEAR] = input.length === 2 ? hooks.parseTwoDigitYear(input) : toInt(input);
});
addParseToken('YY', function (input, array) {
    array[YEAR] = hooks.parseTwoDigitYear(input);
});
addParseToken('Y', function (input, array) {
    array[YEAR] = parseInt(input, 10);
});

// HELPERS

function daysInYear(year) {
    return isLeapYear(year) ? 366 : 365;
}

function isLeapYear(year) {
    return (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;
}

// HOOKS

hooks.parseTwoDigitYear = function (input) {
    return toInt(input) + (toInt(input) > 68 ? 1900 : 2000);
};

// MOMENTS

var getSetYear = makeGetSet('FullYear', true);

function getIsLeapYear () {
    return isLeapYear(this.year());
}

function makeGetSet (unit, keepTime) {
    return function (value) {
        if (value != null) {
            set$1(this, unit, value);
            hooks.updateOffset(this, keepTime);
            return this;
        } else {
            return get(this, unit);
        }
    };
}

function get (mom, unit) {
    return mom.isValid() ?
        mom._d['get' + (mom._isUTC ? 'UTC' : '') + unit]() : NaN;
}

function set$1 (mom, unit, value) {
    if (mom.isValid() && !isNaN(value)) {
        if (unit === 'FullYear' && isLeapYear(mom.year()) && mom.month() === 1 && mom.date() === 29) {
            mom._d['set' + (mom._isUTC ? 'UTC' : '') + unit](value, mom.month(), daysInMonth(value, mom.month()));
        }
        else {
            mom._d['set' + (mom._isUTC ? 'UTC' : '') + unit](value);
        }
    }
}

// MOMENTS

function stringGet (units) {
    units = normalizeUnits(units);
    if (isFunction(this[units])) {
        return this[units]();
    }
    return this;
}


function stringSet (units, value) {
    if (typeof units === 'object') {
        units = normalizeObjectUnits(units);
        var prioritized = getPrioritizedUnits(units);
        for (var i = 0; i < prioritized.length; i++) {
            this[prioritized[i].unit](units[prioritized[i].unit]);
        }
    } else {
        units = normalizeUnits(units);
        if (isFunction(this[units])) {
            return this[units](value);
        }
    }
    return this;
}

function mod(n, x) {
    return ((n % x) + x) % x;
}

var indexOf;

if (Array.prototype.indexOf) {
    indexOf = Array.prototype.indexOf;
} else {
    indexOf = function (o) {
        // I know
        var i;
        for (i = 0; i < this.length; ++i) {
            if (this[i] === o) {
                return i;
            }
        }
        return -1;
    };
}

function daysInMonth(year, month) {
    if (isNaN(year) || isNaN(month)) {
        return NaN;
    }
    var modMonth = mod(month, 12);
    year += (month - modMonth) / 12;
    return modMonth === 1 ? (isLeapYear(year) ? 29 : 28) : (31 - modMonth % 7 % 2);
}

// FORMATTING

addFormatToken('M', ['MM', 2], 'Mo', function () {
    return this.month() + 1;
});

addFormatToken('MMM', 0, 0, function (format) {
    return this.localeData().monthsShort(this, format);
});

addFormatToken('MMMM', 0, 0, function (format) {
    return this.localeData().months(this, format);
});

// ALIASES

addUnitAlias('month', 'M');

// PRIORITY

addUnitPriority('month', 8);

// PARSING

addRegexToken('M',    match1to2);
addRegexToken('MM',   match1to2, match2);
addRegexToken('MMM',  function (isStrict, locale) {
    return locale.monthsShortRegex(isStrict);
});
addRegexToken('MMMM', function (isStrict, locale) {
    return locale.monthsRegex(isStrict);
});

addParseToken(['M', 'MM'], function (input, array) {
    array[MONTH] = toInt(input) - 1;
});

addParseToken(['MMM', 'MMMM'], function (input, array, config, token) {
    var month = config._locale.monthsParse(input, token, config._strict);
    // if we didn't find a month name, mark the date as invalid.
    if (month != null) {
        array[MONTH] = month;
    } else {
        getParsingFlags(config).invalidMonth = input;
    }
});

// LOCALES

var MONTHS_IN_FORMAT = /D[oD]?(\[[^\[\]]*\]|\s)+MMMM?/;
var defaultLocaleMonths = 'January_February_March_April_May_June_July_August_September_October_November_December'.split('_');
function localeMonths (m, format) {
    if (!m) {
        return isArray(this._months) ? this._months :
            this._months['standalone'];
    }
    return isArray(this._months) ? this._months[m.month()] :
        this._months[(this._months.isFormat || MONTHS_IN_FORMAT).test(format) ? 'format' : 'standalone'][m.month()];
}

var defaultLocaleMonthsShort = 'Jan_Feb_Mar_Apr_May_Jun_Jul_Aug_Sep_Oct_Nov_Dec'.split('_');
function localeMonthsShort (m, format) {
    if (!m) {
        return isArray(this._monthsShort) ? this._monthsShort :
            this._monthsShort['standalone'];
    }
    return isArray(this._monthsShort) ? this._monthsShort[m.month()] :
        this._monthsShort[MONTHS_IN_FORMAT.test(format) ? 'format' : 'standalone'][m.month()];
}

function handleStrictParse(monthName, format, strict) {
    var i, ii, mom, llc = monthName.toLocaleLowerCase();
    if (!this._monthsParse) {
        // this is not used
        this._monthsParse = [];
        this._longMonthsParse = [];
        this._shortMonthsParse = [];
        for (i = 0; i < 12; ++i) {
            mom = createUTC([2000, i]);
            this._shortMonthsParse[i] = this.monthsShort(mom, '').toLocaleLowerCase();
            this._longMonthsParse[i] = this.months(mom, '').toLocaleLowerCase();
        }
    }

    if (strict) {
        if (format === 'MMM') {
            ii = indexOf.call(this._shortMonthsParse, llc);
            return ii !== -1 ? ii : null;
        } else {
            ii = indexOf.call(this._longMonthsParse, llc);
            return ii !== -1 ? ii : null;
        }
    } else {
        if (format === 'MMM') {
            ii = indexOf.call(this._shortMonthsParse, llc);
            if (ii !== -1) {
                return ii;
            }
            ii = indexOf.call(this._longMonthsParse, llc);
            return ii !== -1 ? ii : null;
        } else {
            ii = indexOf.call(this._longMonthsParse, llc);
            if (ii !== -1) {
                return ii;
            }
            ii = indexOf.call(this._shortMonthsParse, llc);
            return ii !== -1 ? ii : null;
        }
    }
}

function localeMonthsParse (monthName, format, strict) {
    var i, mom, regex;

    if (this._monthsParseExact) {
        return handleStrictParse.call(this, monthName, format, strict);
    }

    if (!this._monthsParse) {
        this._monthsParse = [];
        this._longMonthsParse = [];
        this._shortMonthsParse = [];
    }

    // TODO: add sorting
    // Sorting makes sure if one month (or abbr) is a prefix of another
    // see sorting in computeMonthsParse
    for (i = 0; i < 12; i++) {
        // make the regex if we don't have it already
        mom = createUTC([2000, i]);
        if (strict && !this._longMonthsParse[i]) {
            this._longMonthsParse[i] = new RegExp('^' + this.months(mom, '').replace('.', '') + '$', 'i');
            this._shortMonthsParse[i] = new RegExp('^' + this.monthsShort(mom, '').replace('.', '') + '$', 'i');
        }
        if (!strict && !this._monthsParse[i]) {
            regex = '^' + this.months(mom, '') + '|^' + this.monthsShort(mom, '');
            this._monthsParse[i] = new RegExp(regex.replace('.', ''), 'i');
        }
        // test the regex
        if (strict && format === 'MMMM' && this._longMonthsParse[i].test(monthName)) {
            return i;
        } else if (strict && format === 'MMM' && this._shortMonthsParse[i].test(monthName)) {
            return i;
        } else if (!strict && this._monthsParse[i].test(monthName)) {
            return i;
        }
    }
}

// MOMENTS

function setMonth (mom, value) {
    var dayOfMonth;

    if (!mom.isValid()) {
        // No op
        return mom;
    }

    if (typeof value === 'string') {
        if (/^\d+$/.test(value)) {
            value = toInt(value);
        } else {
            value = mom.localeData().monthsParse(value);
            // TODO: Another silent failure?
            if (!isNumber(value)) {
                return mom;
            }
        }
    }

    dayOfMonth = Math.min(mom.date(), daysInMonth(mom.year(), value));
    mom._d['set' + (mom._isUTC ? 'UTC' : '') + 'Month'](value, dayOfMonth);
    return mom;
}

function getSetMonth (value) {
    if (value != null) {
        setMonth(this, value);
        hooks.updateOffset(this, true);
        return this;
    } else {
        return get(this, 'Month');
    }
}

function getDaysInMonth () {
    return daysInMonth(this.year(), this.month());
}

var defaultMonthsShortRegex = matchWord;
function monthsShortRegex (isStrict) {
    if (this._monthsParseExact) {
        if (!hasOwnProp(this, '_monthsRegex')) {
            computeMonthsParse.call(this);
        }
        if (isStrict) {
            return this._monthsShortStrictRegex;
        } else {
            return this._monthsShortRegex;
        }
    } else {
        if (!hasOwnProp(this, '_monthsShortRegex')) {
            this._monthsShortRegex = defaultMonthsShortRegex;
        }
        return this._monthsShortStrictRegex && isStrict ?
            this._monthsShortStrictRegex : this._monthsShortRegex;
    }
}

var defaultMonthsRegex = matchWord;
function monthsRegex (isStrict) {
    if (this._monthsParseExact) {
        if (!hasOwnProp(this, '_monthsRegex')) {
            computeMonthsParse.call(this);
        }
        if (isStrict) {
            return this._monthsStrictRegex;
        } else {
            return this._monthsRegex;
        }
    } else {
        if (!hasOwnProp(this, '_monthsRegex')) {
            this._monthsRegex = defaultMonthsRegex;
        }
        return this._monthsStrictRegex && isStrict ?
            this._monthsStrictRegex : this._monthsRegex;
    }
}

function computeMonthsParse () {
    function cmpLenRev(a, b) {
        return b.length - a.length;
    }

    var shortPieces = [], longPieces = [], mixedPieces = [],
        i, mom;
    for (i = 0; i < 12; i++) {
        // make the regex if we don't have it already
        mom = createUTC([2000, i]);
        shortPieces.push(this.monthsShort(mom, ''));
        longPieces.push(this.months(mom, ''));
        mixedPieces.push(this.months(mom, ''));
        mixedPieces.push(this.monthsShort(mom, ''));
    }
    // Sorting makes sure if one month (or abbr) is a prefix of another it
    // will match the longer piece.
    shortPieces.sort(cmpLenRev);
    longPieces.sort(cmpLenRev);
    mixedPieces.sort(cmpLenRev);
    for (i = 0; i < 12; i++) {
        shortPieces[i] = regexEscape(shortPieces[i]);
        longPieces[i] = regexEscape(longPieces[i]);
    }
    for (i = 0; i < 24; i++) {
        mixedPieces[i] = regexEscape(mixedPieces[i]);
    }

    this._monthsRegex = new RegExp('^(' + mixedPieces.join('|') + ')', 'i');
    this._monthsShortRegex = this._monthsRegex;
    this._monthsStrictRegex = new RegExp('^(' + longPieces.join('|') + ')', 'i');
    this._monthsShortStrictRegex = new RegExp('^(' + shortPieces.join('|') + ')', 'i');
}

function createDate (y, m, d, h, M, s, ms) {
    // can't just apply() to create a date:
    // https://stackoverflow.com/q/181348
    var date = new Date(y, m, d, h, M, s, ms);

    // the date constructor remaps years 0-99 to 1900-1999
    if (y < 100 && y >= 0 && isFinite(date.getFullYear())) {
        date.setFullYear(y);
    }
    return date;
}

function createUTCDate (y) {
    var date = new Date(Date.UTC.apply(null, arguments));

    // the Date.UTC function remaps years 0-99 to 1900-1999
    if (y < 100 && y >= 0 && isFinite(date.getUTCFullYear())) {
        date.setUTCFullYear(y);
    }
    return date;
}

// start-of-first-week - start-of-year
function firstWeekOffset(year, dow, doy) {
    var // first-week day -- which january is always in the first week (4 for iso, 1 for other)
        fwd = 7 + dow - doy,
        // first-week day local weekday -- which local weekday is fwd
        fwdlw = (7 + createUTCDate(year, 0, fwd).getUTCDay() - dow) % 7;

    return -fwdlw + fwd - 1;
}

// https://en.wikipedia.org/wiki/ISO_week_date#Calculating_a_date_given_the_year.2C_week_number_and_weekday
function dayOfYearFromWeeks(year, week, weekday, dow, doy) {
    var localWeekday = (7 + weekday - dow) % 7,
        weekOffset = firstWeekOffset(year, dow, doy),
        dayOfYear = 1 + 7 * (week - 1) + localWeekday + weekOffset,
        resYear, resDayOfYear;

    if (dayOfYear <= 0) {
        resYear = year - 1;
        resDayOfYear = daysInYear(resYear) + dayOfYear;
    } else if (dayOfYear > daysInYear(year)) {
        resYear = year + 1;
        resDayOfYear = dayOfYear - daysInYear(year);
    } else {
        resYear = year;
        resDayOfYear = dayOfYear;
    }

    return {
        year: resYear,
        dayOfYear: resDayOfYear
    };
}

function weekOfYear(mom, dow, doy) {
    var weekOffset = firstWeekOffset(mom.year(), dow, doy),
        week = Math.floor((mom.dayOfYear() - weekOffset - 1) / 7) + 1,
        resWeek, resYear;

    if (week < 1) {
        resYear = mom.year() - 1;
        resWeek = week + weeksInYear(resYear, dow, doy);
    } else if (week > weeksInYear(mom.year(), dow, doy)) {
        resWeek = week - weeksInYear(mom.year(), dow, doy);
        resYear = mom.year() + 1;
    } else {
        resYear = mom.year();
        resWeek = week;
    }

    return {
        week: resWeek,
        year: resYear
    };
}

function weeksInYear(year, dow, doy) {
    var weekOffset = firstWeekOffset(year, dow, doy),
        weekOffsetNext = firstWeekOffset(year + 1, dow, doy);
    return (daysInYear(year) - weekOffset + weekOffsetNext) / 7;
}

// FORMATTING

addFormatToken('w', ['ww', 2], 'wo', 'week');
addFormatToken('W', ['WW', 2], 'Wo', 'isoWeek');

// ALIASES

addUnitAlias('week', 'w');
addUnitAlias('isoWeek', 'W');

// PRIORITIES

addUnitPriority('week', 5);
addUnitPriority('isoWeek', 5);

// PARSING

addRegexToken('w',  match1to2);
addRegexToken('ww', match1to2, match2);
addRegexToken('W',  match1to2);
addRegexToken('WW', match1to2, match2);

addWeekParseToken(['w', 'ww', 'W', 'WW'], function (input, week, config, token) {
    week[token.substr(0, 1)] = toInt(input);
});

// HELPERS

// LOCALES

function localeWeek (mom) {
    return weekOfYear(mom, this._week.dow, this._week.doy).week;
}

var defaultLocaleWeek = {
    dow : 0, // Sunday is the first day of the week.
    doy : 6  // The week that contains Jan 1st is the first week of the year.
};

function localeFirstDayOfWeek () {
    return this._week.dow;
}

function localeFirstDayOfYear () {
    return this._week.doy;
}

// MOMENTS

function getSetWeek (input) {
    var week = this.localeData().week(this);
    return input == null ? week : this.add((input - week) * 7, 'd');
}

function getSetISOWeek (input) {
    var week = weekOfYear(this, 1, 4).week;
    return input == null ? week : this.add((input - week) * 7, 'd');
}

// FORMATTING

addFormatToken('d', 0, 'do', 'day');

addFormatToken('dd', 0, 0, function (format) {
    return this.localeData().weekdaysMin(this, format);
});

addFormatToken('ddd', 0, 0, function (format) {
    return this.localeData().weekdaysShort(this, format);
});

addFormatToken('dddd', 0, 0, function (format) {
    return this.localeData().weekdays(this, format);
});

addFormatToken('e', 0, 0, 'weekday');
addFormatToken('E', 0, 0, 'isoWeekday');

// ALIASES

addUnitAlias('day', 'd');
addUnitAlias('weekday', 'e');
addUnitAlias('isoWeekday', 'E');

// PRIORITY
addUnitPriority('day', 11);
addUnitPriority('weekday', 11);
addUnitPriority('isoWeekday', 11);

// PARSING

addRegexToken('d',    match1to2);
addRegexToken('e',    match1to2);
addRegexToken('E',    match1to2);
addRegexToken('dd',   function (isStrict, locale) {
    return locale.weekdaysMinRegex(isStrict);
});
addRegexToken('ddd',   function (isStrict, locale) {
    return locale.weekdaysShortRegex(isStrict);
});
addRegexToken('dddd',   function (isStrict, locale) {
    return locale.weekdaysRegex(isStrict);
});

addWeekParseToken(['dd', 'ddd', 'dddd'], function (input, week, config, token) {
    var weekday = config._locale.weekdaysParse(input, token, config._strict);
    // if we didn't get a weekday name, mark the date as invalid
    if (weekday != null) {
        week.d = weekday;
    } else {
        getParsingFlags(config).invalidWeekday = input;
    }
});

addWeekParseToken(['d', 'e', 'E'], function (input, week, config, token) {
    week[token] = toInt(input);
});

// HELPERS

function parseWeekday(input, locale) {
    if (typeof input !== 'string') {
        return input;
    }

    if (!isNaN(input)) {
        return parseInt(input, 10);
    }

    input = locale.weekdaysParse(input);
    if (typeof input === 'number') {
        return input;
    }

    return null;
}

function parseIsoWeekday(input, locale) {
    if (typeof input === 'string') {
        return locale.weekdaysParse(input) % 7 || 7;
    }
    return isNaN(input) ? null : input;
}

// LOCALES

var defaultLocaleWeekdays = 'Sunday_Monday_Tuesday_Wednesday_Thursday_Friday_Saturday'.split('_');
function localeWeekdays (m, format) {
    if (!m) {
        return isArray(this._weekdays) ? this._weekdays :
            this._weekdays['standalone'];
    }
    return isArray(this._weekdays) ? this._weekdays[m.day()] :
        this._weekdays[this._weekdays.isFormat.test(format) ? 'format' : 'standalone'][m.day()];
}

var defaultLocaleWeekdaysShort = 'Sun_Mon_Tue_Wed_Thu_Fri_Sat'.split('_');
function localeWeekdaysShort (m) {
    return (m) ? this._weekdaysShort[m.day()] : this._weekdaysShort;
}

var defaultLocaleWeekdaysMin = 'Su_Mo_Tu_We_Th_Fr_Sa'.split('_');
function localeWeekdaysMin (m) {
    return (m) ? this._weekdaysMin[m.day()] : this._weekdaysMin;
}

function handleStrictParse$1(weekdayName, format, strict) {
    var i, ii, mom, llc = weekdayName.toLocaleLowerCase();
    if (!this._weekdaysParse) {
        this._weekdaysParse = [];
        this._shortWeekdaysParse = [];
        this._minWeekdaysParse = [];

        for (i = 0; i < 7; ++i) {
            mom = createUTC([2000, 1]).day(i);
            this._minWeekdaysParse[i] = this.weekdaysMin(mom, '').toLocaleLowerCase();
            this._shortWeekdaysParse[i] = this.weekdaysShort(mom, '').toLocaleLowerCase();
            this._weekdaysParse[i] = this.weekdays(mom, '').toLocaleLowerCase();
        }
    }

    if (strict) {
        if (format === 'dddd') {
            ii = indexOf.call(this._weekdaysParse, llc);
            return ii !== -1 ? ii : null;
        } else if (format === 'ddd') {
            ii = indexOf.call(this._shortWeekdaysParse, llc);
            return ii !== -1 ? ii : null;
        } else {
            ii = indexOf.call(this._minWeekdaysParse, llc);
            return ii !== -1 ? ii : null;
        }
    } else {
        if (format === 'dddd') {
            ii = indexOf.call(this._weekdaysParse, llc);
            if (ii !== -1) {
                return ii;
            }
            ii = indexOf.call(this._shortWeekdaysParse, llc);
            if (ii !== -1) {
                return ii;
            }
            ii = indexOf.call(this._minWeekdaysParse, llc);
            return ii !== -1 ? ii : null;
        } else if (format === 'ddd') {
            ii = indexOf.call(this._shortWeekdaysParse, llc);
            if (ii !== -1) {
                return ii;
            }
            ii = indexOf.call(this._weekdaysParse, llc);
            if (ii !== -1) {
                return ii;
            }
            ii = indexOf.call(this._minWeekdaysParse, llc);
            return ii !== -1 ? ii : null;
        } else {
            ii = indexOf.call(this._minWeekdaysParse, llc);
            if (ii !== -1) {
                return ii;
            }
            ii = indexOf.call(this._weekdaysParse, llc);
            if (ii !== -1) {
                return ii;
            }
            ii = indexOf.call(this._shortWeekdaysParse, llc);
            return ii !== -1 ? ii : null;
        }
    }
}

function localeWeekdaysParse (weekdayName, format, strict) {
    var i, mom, regex;

    if (this._weekdaysParseExact) {
        return handleStrictParse$1.call(this, weekdayName, format, strict);
    }

    if (!this._weekdaysParse) {
        this._weekdaysParse = [];
        this._minWeekdaysParse = [];
        this._shortWeekdaysParse = [];
        this._fullWeekdaysParse = [];
    }

    for (i = 0; i < 7; i++) {
        // make the regex if we don't have it already

        mom = createUTC([2000, 1]).day(i);
        if (strict && !this._fullWeekdaysParse[i]) {
            this._fullWeekdaysParse[i] = new RegExp('^' + this.weekdays(mom, '').replace('.', '\.?') + '$', 'i');
            this._shortWeekdaysParse[i] = new RegExp('^' + this.weekdaysShort(mom, '').replace('.', '\.?') + '$', 'i');
            this._minWeekdaysParse[i] = new RegExp('^' + this.weekdaysMin(mom, '').replace('.', '\.?') + '$', 'i');
        }
        if (!this._weekdaysParse[i]) {
            regex = '^' + this.weekdays(mom, '') + '|^' + this.weekdaysShort(mom, '') + '|^' + this.weekdaysMin(mom, '');
            this._weekdaysParse[i] = new RegExp(regex.replace('.', ''), 'i');
        }
        // test the regex
        if (strict && format === 'dddd' && this._fullWeekdaysParse[i].test(weekdayName)) {
            return i;
        } else if (strict && format === 'ddd' && this._shortWeekdaysParse[i].test(weekdayName)) {
            return i;
        } else if (strict && format === 'dd' && this._minWeekdaysParse[i].test(weekdayName)) {
            return i;
        } else if (!strict && this._weekdaysParse[i].test(weekdayName)) {
            return i;
        }
    }
}

// MOMENTS

function getSetDayOfWeek (input) {
    if (!this.isValid()) {
        return input != null ? this : NaN;
    }
    var day = this._isUTC ? this._d.getUTCDay() : this._d.getDay();
    if (input != null) {
        input = parseWeekday(input, this.localeData());
        return this.add(input - day, 'd');
    } else {
        return day;
    }
}

function getSetLocaleDayOfWeek (input) {
    if (!this.isValid()) {
        return input != null ? this : NaN;
    }
    var weekday = (this.day() + 7 - this.localeData()._week.dow) % 7;
    return input == null ? weekday : this.add(input - weekday, 'd');
}

function getSetISODayOfWeek (input) {
    if (!this.isValid()) {
        return input != null ? this : NaN;
    }

    // behaves the same as moment#day except
    // as a getter, returns 7 instead of 0 (1-7 range instead of 0-6)
    // as a setter, sunday should belong to the previous week.

    if (input != null) {
        var weekday = parseIsoWeekday(input, this.localeData());
        return this.day(this.day() % 7 ? weekday : weekday - 7);
    } else {
        return this.day() || 7;
    }
}

var defaultWeekdaysRegex = matchWord;
function weekdaysRegex (isStrict) {
    if (this._weekdaysParseExact) {
        if (!hasOwnProp(this, '_weekdaysRegex')) {
            computeWeekdaysParse.call(this);
        }
        if (isStrict) {
            return this._weekdaysStrictRegex;
        } else {
            return this._weekdaysRegex;
        }
    } else {
        if (!hasOwnProp(this, '_weekdaysRegex')) {
            this._weekdaysRegex = defaultWeekdaysRegex;
        }
        return this._weekdaysStrictRegex && isStrict ?
            this._weekdaysStrictRegex : this._weekdaysRegex;
    }
}

var defaultWeekdaysShortRegex = matchWord;
function weekdaysShortRegex (isStrict) {
    if (this._weekdaysParseExact) {
        if (!hasOwnProp(this, '_weekdaysRegex')) {
            computeWeekdaysParse.call(this);
        }
        if (isStrict) {
            return this._weekdaysShortStrictRegex;
        } else {
            return this._weekdaysShortRegex;
        }
    } else {
        if (!hasOwnProp(this, '_weekdaysShortRegex')) {
            this._weekdaysShortRegex = defaultWeekdaysShortRegex;
        }
        return this._weekdaysShortStrictRegex && isStrict ?
            this._weekdaysShortStrictRegex : this._weekdaysShortRegex;
    }
}

var defaultWeekdaysMinRegex = matchWord;
function weekdaysMinRegex (isStrict) {
    if (this._weekdaysParseExact) {
        if (!hasOwnProp(this, '_weekdaysRegex')) {
            computeWeekdaysParse.call(this);
        }
        if (isStrict) {
            return this._weekdaysMinStrictRegex;
        } else {
            return this._weekdaysMinRegex;
        }
    } else {
        if (!hasOwnProp(this, '_weekdaysMinRegex')) {
            this._weekdaysMinRegex = defaultWeekdaysMinRegex;
        }
        return this._weekdaysMinStrictRegex && isStrict ?
            this._weekdaysMinStrictRegex : this._weekdaysMinRegex;
    }
}


function computeWeekdaysParse () {
    function cmpLenRev(a, b) {
        return b.length - a.length;
    }

    var minPieces = [], shortPieces = [], longPieces = [], mixedPieces = [],
        i, mom, minp, shortp, longp;
    for (i = 0; i < 7; i++) {
        // make the regex if we don't have it already
        mom = createUTC([2000, 1]).day(i);
        minp = this.weekdaysMin(mom, '');
        shortp = this.weekdaysShort(mom, '');
        longp = this.weekdays(mom, '');
        minPieces.push(minp);
        shortPieces.push(shortp);
        longPieces.push(longp);
        mixedPieces.push(minp);
        mixedPieces.push(shortp);
        mixedPieces.push(longp);
    }
    // Sorting makes sure if one weekday (or abbr) is a prefix of another it
    // will match the longer piece.
    minPieces.sort(cmpLenRev);
    shortPieces.sort(cmpLenRev);
    longPieces.sort(cmpLenRev);
    mixedPieces.sort(cmpLenRev);
    for (i = 0; i < 7; i++) {
        shortPieces[i] = regexEscape(shortPieces[i]);
        longPieces[i] = regexEscape(longPieces[i]);
        mixedPieces[i] = regexEscape(mixedPieces[i]);
    }

    this._weekdaysRegex = new RegExp('^(' + mixedPieces.join('|') + ')', 'i');
    this._weekdaysShortRegex = this._weekdaysRegex;
    this._weekdaysMinRegex = this._weekdaysRegex;

    this._weekdaysStrictRegex = new RegExp('^(' + longPieces.join('|') + ')', 'i');
    this._weekdaysShortStrictRegex = new RegExp('^(' + shortPieces.join('|') + ')', 'i');
    this._weekdaysMinStrictRegex = new RegExp('^(' + minPieces.join('|') + ')', 'i');
}

// FORMATTING

function hFormat() {
    return this.hours() % 12 || 12;
}

function kFormat() {
    return this.hours() || 24;
}

addFormatToken('H', ['HH', 2], 0, 'hour');
addFormatToken('h', ['hh', 2], 0, hFormat);
addFormatToken('k', ['kk', 2], 0, kFormat);

addFormatToken('hmm', 0, 0, function () {
    return '' + hFormat.apply(this) + zeroFill(this.minutes(), 2);
});

addFormatToken('hmmss', 0, 0, function () {
    return '' + hFormat.apply(this) + zeroFill(this.minutes(), 2) +
        zeroFill(this.seconds(), 2);
});

addFormatToken('Hmm', 0, 0, function () {
    return '' + this.hours() + zeroFill(this.minutes(), 2);
});

addFormatToken('Hmmss', 0, 0, function () {
    return '' + this.hours() + zeroFill(this.minutes(), 2) +
        zeroFill(this.seconds(), 2);
});

function meridiem (token, lowercase) {
    addFormatToken(token, 0, 0, function () {
        return this.localeData().meridiem(this.hours(), this.minutes(), lowercase);
    });
}

meridiem('a', true);
meridiem('A', false);

// ALIASES

addUnitAlias('hour', 'h');

// PRIORITY
addUnitPriority('hour', 13);

// PARSING

function matchMeridiem (isStrict, locale) {
    return locale._meridiemParse;
}

addRegexToken('a',  matchMeridiem);
addRegexToken('A',  matchMeridiem);
addRegexToken('H',  match1to2);
addRegexToken('h',  match1to2);
addRegexToken('k',  match1to2);
addRegexToken('HH', match1to2, match2);
addRegexToken('hh', match1to2, match2);
addRegexToken('kk', match1to2, match2);

addRegexToken('hmm', match3to4);
addRegexToken('hmmss', match5to6);
addRegexToken('Hmm', match3to4);
addRegexToken('Hmmss', match5to6);

addParseToken(['H', 'HH'], HOUR);
addParseToken(['k', 'kk'], function (input, array, config) {
    var kInput = toInt(input);
    array[HOUR] = kInput === 24 ? 0 : kInput;
});
addParseToken(['a', 'A'], function (input, array, config) {
    config._isPm = config._locale.isPM(input);
    config._meridiem = input;
});
addParseToken(['h', 'hh'], function (input, array, config) {
    array[HOUR] = toInt(input);
    getParsingFlags(config).bigHour = true;
});
addParseToken('hmm', function (input, array, config) {
    var pos = input.length - 2;
    array[HOUR] = toInt(input.substr(0, pos));
    array[MINUTE] = toInt(input.substr(pos));
    getParsingFlags(config).bigHour = true;
});
addParseToken('hmmss', function (input, array, config) {
    var pos1 = input.length - 4;
    var pos2 = input.length - 2;
    array[HOUR] = toInt(input.substr(0, pos1));
    array[MINUTE] = toInt(input.substr(pos1, 2));
    array[SECOND] = toInt(input.substr(pos2));
    getParsingFlags(config).bigHour = true;
});
addParseToken('Hmm', function (input, array, config) {
    var pos = input.length - 2;
    array[HOUR] = toInt(input.substr(0, pos));
    array[MINUTE] = toInt(input.substr(pos));
});
addParseToken('Hmmss', function (input, array, config) {
    var pos1 = input.length - 4;
    var pos2 = input.length - 2;
    array[HOUR] = toInt(input.substr(0, pos1));
    array[MINUTE] = toInt(input.substr(pos1, 2));
    array[SECOND] = toInt(input.substr(pos2));
});

// LOCALES

function localeIsPM (input) {
    // IE8 Quirks Mode & IE7 Standards Mode do not allow accessing strings like arrays
    // Using charAt should be more compatible.
    return ((input + '').toLowerCase().charAt(0) === 'p');
}

var defaultLocaleMeridiemParse = /[ap]\.?m?\.?/i;
function localeMeridiem (hours, minutes, isLower) {
    if (hours > 11) {
        return isLower ? 'pm' : 'PM';
    } else {
        return isLower ? 'am' : 'AM';
    }
}


// MOMENTS

// Setting the hour should keep the time, because the user explicitly
// specified which hour he wants. So trying to maintain the same hour (in
// a new timezone) makes sense. Adding/subtracting hours does not follow
// this rule.
var getSetHour = makeGetSet('Hours', true);

// months
// week
// weekdays
// meridiem
var baseConfig = {
    calendar: defaultCalendar,
    longDateFormat: defaultLongDateFormat,
    invalidDate: defaultInvalidDate,
    ordinal: defaultOrdinal,
    dayOfMonthOrdinalParse: defaultDayOfMonthOrdinalParse,
    relativeTime: defaultRelativeTime,

    months: defaultLocaleMonths,
    monthsShort: defaultLocaleMonthsShort,

    week: defaultLocaleWeek,

    weekdays: defaultLocaleWeekdays,
    weekdaysMin: defaultLocaleWeekdaysMin,
    weekdaysShort: defaultLocaleWeekdaysShort,

    meridiemParse: defaultLocaleMeridiemParse
};

// internal storage for locale config files
var locales = {};
var localeFamilies = {};
var globalLocale;

function normalizeLocale(key) {
    return key ? key.toLowerCase().replace('_', '-') : key;
}

// pick the locale from the array
// try ['en-au', 'en-gb'] as 'en-au', 'en-gb', 'en', as in move through the list trying each
// substring from most specific to least, but move to the next array item if it's a more specific variant than the current root
function chooseLocale(names) {
    var i = 0, j, next, locale, split;

    while (i < names.length) {
        split = normalizeLocale(names[i]).split('-');
        j = split.length;
        next = normalizeLocale(names[i + 1]);
        next = next ? next.split('-') : null;
        while (j > 0) {
            locale = loadLocale(split.slice(0, j).join('-'));
            if (locale) {
                return locale;
            }
            if (next && next.length >= j && compareArrays(split, next, true) >= j - 1) {
                //the next array item is better than a shallower substring of this one
                break;
            }
            j--;
        }
        i++;
    }
    return null;
}

function loadLocale(name) {
    var oldLocale = null;
    // TODO: Find a better way to register and load all the locales in Node
    if (!locales[name] && (typeof module !== 'undefined') &&
            module && module.exports) {
        try {
            oldLocale = globalLocale._abbr;
            var aliasedRequire = require;
            aliasedRequire('./locale/' + name);
            getSetGlobalLocale(oldLocale);
        } catch (e) {}
    }
    return locales[name];
}

// This function will load locale and then set the global locale.  If
// no arguments are passed in, it will simply return the current global
// locale key.
function getSetGlobalLocale (key, values) {
    var data;
    if (key) {
        if (isUndefined(values)) {
            data = getLocale(key);
        }
        else {
            data = defineLocale(key, values);
        }

        if (data) {
            // moment.duration._locale = moment._locale = data;
            globalLocale = data;
        }
    }

    return globalLocale._abbr;
}

function defineLocale (name, config) {
    if (config !== null) {
        var parentConfig = baseConfig;
        config.abbr = name;
        if (locales[name] != null) {
            deprecateSimple('defineLocaleOverride',
                    'use moment.updateLocale(localeName, config) to change ' +
                    'an existing locale. moment.defineLocale(localeName, ' +
                    'config) should only be used for creating a new locale ' +
                    'See http://momentjs.com/guides/#/warnings/define-locale/ for more info.');
            parentConfig = locales[name]._config;
        } else if (config.parentLocale != null) {
            if (locales[config.parentLocale] != null) {
                parentConfig = locales[config.parentLocale]._config;
            } else {
                if (!localeFamilies[config.parentLocale]) {
                    localeFamilies[config.parentLocale] = [];
                }
                localeFamilies[config.parentLocale].push({
                    name: name,
                    config: config
                });
                return null;
            }
        }
        locales[name] = new Locale(mergeConfigs(parentConfig, config));

        if (localeFamilies[name]) {
            localeFamilies[name].forEach(function (x) {
                defineLocale(x.name, x.config);
            });
        }

        // backwards compat for now: also set the locale
        // make sure we set the locale AFTER all child locales have been
        // created, so we won't end up with the child locale set.
        getSetGlobalLocale(name);


        return locales[name];
    } else {
        // useful for testing
        delete locales[name];
        return null;
    }
}

function updateLocale(name, config) {
    if (config != null) {
        var locale, tmpLocale, parentConfig = baseConfig;
        // MERGE
        tmpLocale = loadLocale(name);
        if (tmpLocale != null) {
            parentConfig = tmpLocale._config;
        }
        config = mergeConfigs(parentConfig, config);
        locale = new Locale(config);
        locale.parentLocale = locales[name];
        locales[name] = locale;

        // backwards compat for now: also set the locale
        getSetGlobalLocale(name);
    } else {
        // pass null for config to unupdate, useful for tests
        if (locales[name] != null) {
            if (locales[name].parentLocale != null) {
                locales[name] = locales[name].parentLocale;
            } else if (locales[name] != null) {
                delete locales[name];
            }
        }
    }
    return locales[name];
}

// returns locale data
function getLocale (key) {
    var locale;

    if (key && key._locale && key._locale._abbr) {
        key = key._locale._abbr;
    }

    if (!key) {
        return globalLocale;
    }

    if (!isArray(key)) {
        //short-circuit everything else
        locale = loadLocale(key);
        if (locale) {
            return locale;
        }
        key = [key];
    }

    return chooseLocale(key);
}

function listLocales() {
    return keys(locales);
}

function checkOverflow (m) {
    var overflow;
    var a = m._a;

    if (a && getParsingFlags(m).overflow === -2) {
        overflow =
            a[MONTH]       < 0 || a[MONTH]       > 11  ? MONTH :
            a[DATE]        < 1 || a[DATE]        > daysInMonth(a[YEAR], a[MONTH]) ? DATE :
            a[HOUR]        < 0 || a[HOUR]        > 24 || (a[HOUR] === 24 && (a[MINUTE] !== 0 || a[SECOND] !== 0 || a[MILLISECOND] !== 0)) ? HOUR :
            a[MINUTE]      < 0 || a[MINUTE]      > 59  ? MINUTE :
            a[SECOND]      < 0 || a[SECOND]      > 59  ? SECOND :
            a[MILLISECOND] < 0 || a[MILLISECOND] > 999 ? MILLISECOND :
            -1;

        if (getParsingFlags(m)._overflowDayOfYear && (overflow < YEAR || overflow > DATE)) {
            overflow = DATE;
        }
        if (getParsingFlags(m)._overflowWeeks && overflow === -1) {
            overflow = WEEK;
        }
        if (getParsingFlags(m)._overflowWeekday && overflow === -1) {
            overflow = WEEKDAY;
        }

        getParsingFlags(m).overflow = overflow;
    }

    return m;
}

// Pick the first defined of two or three arguments.
function defaults(a, b, c) {
    if (a != null) {
        return a;
    }
    if (b != null) {
        return b;
    }
    return c;
}

function currentDateArray(config) {
    // hooks is actually the exported moment object
    var nowValue = new Date(hooks.now());
    if (config._useUTC) {
        return [nowValue.getUTCFullYear(), nowValue.getUTCMonth(), nowValue.getUTCDate()];
    }
    return [nowValue.getFullYear(), nowValue.getMonth(), nowValue.getDate()];
}

// convert an array to a date.
// the array should mirror the parameters below
// note: all values past the year are optional and will default to the lowest possible value.
// [year, month, day , hour, minute, second, millisecond]
function configFromArray (config) {
    var i, date, input = [], currentDate, expectedWeekday, yearToUse;

    if (config._d) {
        return;
    }

    currentDate = currentDateArray(config);

    //compute day of the year from weeks and weekdays
    if (config._w && config._a[DATE] == null && config._a[MONTH] == null) {
        dayOfYearFromWeekInfo(config);
    }

    //if the day of the year is set, figure out what it is
    if (config._dayOfYear != null) {
        yearToUse = defaults(config._a[YEAR], currentDate[YEAR]);

        if (config._dayOfYear > daysInYear(yearToUse) || config._dayOfYear === 0) {
            getParsingFlags(config)._overflowDayOfYear = true;
        }

        date = createUTCDate(yearToUse, 0, config._dayOfYear);
        config._a[MONTH] = date.getUTCMonth();
        config._a[DATE] = date.getUTCDate();
    }

    // Default to current date.
    // * if no year, month, day of month are given, default to today
    // * if day of month is given, default month and year
    // * if month is given, default only year
    // * if year is given, don't default anything
    for (i = 0; i < 3 && config._a[i] == null; ++i) {
        config._a[i] = input[i] = currentDate[i];
    }

    // Zero out whatever was not defaulted, including time
    for (; i < 7; i++) {
        config._a[i] = input[i] = (config._a[i] == null) ? (i === 2 ? 1 : 0) : config._a[i];
    }

    // Check for 24:00:00.000
    if (config._a[HOUR] === 24 &&
            config._a[MINUTE] === 0 &&
            config._a[SECOND] === 0 &&
            config._a[MILLISECOND] === 0) {
        config._nextDay = true;
        config._a[HOUR] = 0;
    }

    config._d = (config._useUTC ? createUTCDate : createDate).apply(null, input);
    expectedWeekday = config._useUTC ? config._d.getUTCDay() : config._d.getDay();

    // Apply timezone offset from input. The actual utcOffset can be changed
    // with parseZone.
    if (config._tzm != null) {
        config._d.setUTCMinutes(config._d.getUTCMinutes() - config._tzm);
    }

    if (config._nextDay) {
        config._a[HOUR] = 24;
    }

    // check for mismatching day of week
    if (config._w && typeof config._w.d !== 'undefined' && config._w.d !== expectedWeekday) {
        getParsingFlags(config).weekdayMismatch = true;
    }
}

function dayOfYearFromWeekInfo(config) {
    var w, weekYear, week, weekday, dow, doy, temp, weekdayOverflow;

    w = config._w;
    if (w.GG != null || w.W != null || w.E != null) {
        dow = 1;
        doy = 4;

        // TODO: We need to take the current isoWeekYear, but that depends on
        // how we interpret now (local, utc, fixed offset). So create
        // a now version of current config (take local/utc/offset flags, and
        // create now).
        weekYear = defaults(w.GG, config._a[YEAR], weekOfYear(createLocal(), 1, 4).year);
        week = defaults(w.W, 1);
        weekday = defaults(w.E, 1);
        if (weekday < 1 || weekday > 7) {
            weekdayOverflow = true;
        }
    } else {
        dow = config._locale._week.dow;
        doy = config._locale._week.doy;

        var curWeek = weekOfYear(createLocal(), dow, doy);

        weekYear = defaults(w.gg, config._a[YEAR], curWeek.year);

        // Default to current week.
        week = defaults(w.w, curWeek.week);

        if (w.d != null) {
            // weekday -- low day numbers are considered next week
            weekday = w.d;
            if (weekday < 0 || weekday > 6) {
                weekdayOverflow = true;
            }
        } else if (w.e != null) {
            // local weekday -- counting starts from begining of week
            weekday = w.e + dow;
            if (w.e < 0 || w.e > 6) {
                weekdayOverflow = true;
            }
        } else {
            // default to begining of week
            weekday = dow;
        }
    }
    if (week < 1 || week > weeksInYear(weekYear, dow, doy)) {
        getParsingFlags(config)._overflowWeeks = true;
    } else if (weekdayOverflow != null) {
        getParsingFlags(config)._overflowWeekday = true;
    } else {
        temp = dayOfYearFromWeeks(weekYear, week, weekday, dow, doy);
        config._a[YEAR] = temp.year;
        config._dayOfYear = temp.dayOfYear;
    }
}

// iso 8601 regex
// 0000-00-00 0000-W00 or 0000-W00-0 + T + 00 or 00:00 or 00:00:00 or 00:00:00.000 + +00:00 or +0000 or +00)
var extendedIsoRegex = /^\s*((?:[+-]\d{6}|\d{4})-(?:\d\d-\d\d|W\d\d-\d|W\d\d|\d\d\d|\d\d))(?:(T| )(\d\d(?::\d\d(?::\d\d(?:[.,]\d+)?)?)?)([\+\-]\d\d(?::?\d\d)?|\s*Z)?)?$/;
var basicIsoRegex = /^\s*((?:[+-]\d{6}|\d{4})(?:\d\d\d\d|W\d\d\d|W\d\d|\d\d\d|\d\d))(?:(T| )(\d\d(?:\d\d(?:\d\d(?:[.,]\d+)?)?)?)([\+\-]\d\d(?::?\d\d)?|\s*Z)?)?$/;

var tzRegex = /Z|[+-]\d\d(?::?\d\d)?/;

var isoDates = [
    ['YYYYYY-MM-DD', /[+-]\d{6}-\d\d-\d\d/],
    ['YYYY-MM-DD', /\d{4}-\d\d-\d\d/],
    ['GGGG-[W]WW-E', /\d{4}-W\d\d-\d/],
    ['GGGG-[W]WW', /\d{4}-W\d\d/, false],
    ['YYYY-DDD', /\d{4}-\d{3}/],
    ['YYYY-MM', /\d{4}-\d\d/, false],
    ['YYYYYYMMDD', /[+-]\d{10}/],
    ['YYYYMMDD', /\d{8}/],
    // YYYYMM is NOT allowed by the standard
    ['GGGG[W]WWE', /\d{4}W\d{3}/],
    ['GGGG[W]WW', /\d{4}W\d{2}/, false],
    ['YYYYDDD', /\d{7}/]
];

// iso time formats and regexes
var isoTimes = [
    ['HH:mm:ss.SSSS', /\d\d:\d\d:\d\d\.\d+/],
    ['HH:mm:ss,SSSS', /\d\d:\d\d:\d\d,\d+/],
    ['HH:mm:ss', /\d\d:\d\d:\d\d/],
    ['HH:mm', /\d\d:\d\d/],
    ['HHmmss.SSSS', /\d\d\d\d\d\d\.\d+/],
    ['HHmmss,SSSS', /\d\d\d\d\d\d,\d+/],
    ['HHmmss', /\d\d\d\d\d\d/],
    ['HHmm', /\d\d\d\d/],
    ['HH', /\d\d/]
];

var aspNetJsonRegex = /^\/?Date\((\-?\d+)/i;

// date from iso format
function configFromISO(config) {
    var i, l,
        string = config._i,
        match = extendedIsoRegex.exec(string) || basicIsoRegex.exec(string),
        allowTime, dateFormat, timeFormat, tzFormat;

    if (match) {
        getParsingFlags(config).iso = true;

        for (i = 0, l = isoDates.length; i < l; i++) {
            if (isoDates[i][1].exec(match[1])) {
                dateFormat = isoDates[i][0];
                allowTime = isoDates[i][2] !== false;
                break;
            }
        }
        if (dateFormat == null) {
            config._isValid = false;
            return;
        }
        if (match[3]) {
            for (i = 0, l = isoTimes.length; i < l; i++) {
                if (isoTimes[i][1].exec(match[3])) {
                    // match[2] should be 'T' or space
                    timeFormat = (match[2] || ' ') + isoTimes[i][0];
                    break;
                }
            }
            if (timeFormat == null) {
                config._isValid = false;
                return;
            }
        }
        if (!allowTime && timeFormat != null) {
            config._isValid = false;
            return;
        }
        if (match[4]) {
            if (tzRegex.exec(match[4])) {
                tzFormat = 'Z';
            } else {
                config._isValid = false;
                return;
            }
        }
        config._f = dateFormat + (timeFormat || '') + (tzFormat || '');
        configFromStringAndFormat(config);
    } else {
        config._isValid = false;
    }
}

// RFC 2822 regex: For details see https://tools.ietf.org/html/rfc2822#section-3.3
var rfc2822 = /^(?:(Mon|Tue|Wed|Thu|Fri|Sat|Sun),?\s)?(\d{1,2})\s(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s(\d{2,4})\s(\d\d):(\d\d)(?::(\d\d))?\s(?:(UT|GMT|[ECMP][SD]T)|([Zz])|([+-]\d{4}))$/;

function extractFromRFC2822Strings(yearStr, monthStr, dayStr, hourStr, minuteStr, secondStr) {
    var result = [
        untruncateYear(yearStr),
        defaultLocaleMonthsShort.indexOf(monthStr),
        parseInt(dayStr, 10),
        parseInt(hourStr, 10),
        parseInt(minuteStr, 10)
    ];

    if (secondStr) {
        result.push(parseInt(secondStr, 10));
    }

    return result;
}

function untruncateYear(yearStr) {
    var year = parseInt(yearStr, 10);
    if (year <= 49) {
        return 2000 + year;
    } else if (year <= 999) {
        return 1900 + year;
    }
    return year;
}

function preprocessRFC2822(s) {
    // Remove comments and folding whitespace and replace multiple-spaces with a single space
    return s.replace(/\([^)]*\)|[\n\t]/g, ' ').replace(/(\s\s+)/g, ' ').trim();
}

function checkWeekday(weekdayStr, parsedInput, config) {
    if (weekdayStr) {
        // TODO: Replace the vanilla JS Date object with an indepentent day-of-week check.
        var weekdayProvided = defaultLocaleWeekdaysShort.indexOf(weekdayStr),
            weekdayActual = new Date(parsedInput[0], parsedInput[1], parsedInput[2]).getDay();
        if (weekdayProvided !== weekdayActual) {
            getParsingFlags(config).weekdayMismatch = true;
            config._isValid = false;
            return false;
        }
    }
    return true;
}

var obsOffsets = {
    UT: 0,
    GMT: 0,
    EDT: -4 * 60,
    EST: -5 * 60,
    CDT: -5 * 60,
    CST: -6 * 60,
    MDT: -6 * 60,
    MST: -7 * 60,
    PDT: -7 * 60,
    PST: -8 * 60
};

function calculateOffset(obsOffset, militaryOffset, numOffset) {
    if (obsOffset) {
        return obsOffsets[obsOffset];
    } else if (militaryOffset) {
        // the only allowed military tz is Z
        return 0;
    } else {
        var hm = parseInt(numOffset, 10);
        var m = hm % 100, h = (hm - m) / 100;
        return h * 60 + m;
    }
}

// date and time from ref 2822 format
function configFromRFC2822(config) {
    var match = rfc2822.exec(preprocessRFC2822(config._i));
    if (match) {
        var parsedArray = extractFromRFC2822Strings(match[4], match[3], match[2], match[5], match[6], match[7]);
        if (!checkWeekday(match[1], parsedArray, config)) {
            return;
        }

        config._a = parsedArray;
        config._tzm = calculateOffset(match[8], match[9], match[10]);

        config._d = createUTCDate.apply(null, config._a);
        config._d.setUTCMinutes(config._d.getUTCMinutes() - config._tzm);

        getParsingFlags(config).rfc2822 = true;
    } else {
        config._isValid = false;
    }
}

// date from iso format or fallback
function configFromString(config) {
    var matched = aspNetJsonRegex.exec(config._i);

    if (matched !== null) {
        config._d = new Date(+matched[1]);
        return;
    }

    configFromISO(config);
    if (config._isValid === false) {
        delete config._isValid;
    } else {
        return;
    }

    configFromRFC2822(config);
    if (config._isValid === false) {
        delete config._isValid;
    } else {
        return;
    }

    // Final attempt, use Input Fallback
    hooks.createFromInputFallback(config);
}

hooks.createFromInputFallback = deprecate(
    'value provided is not in a recognized RFC2822 or ISO format. moment construction falls back to js Date(), ' +
    'which is not reliable across all browsers and versions. Non RFC2822/ISO date formats are ' +
    'discouraged and will be removed in an upcoming major release. Please refer to ' +
    'http://momentjs.com/guides/#/warnings/js-date/ for more info.',
    function (config) {
        config._d = new Date(config._i + (config._useUTC ? ' UTC' : ''));
    }
);

// constant that refers to the ISO standard
hooks.ISO_8601 = function () {};

// constant that refers to the RFC 2822 form
hooks.RFC_2822 = function () {};

// date from string and format string
function configFromStringAndFormat(config) {
    // TODO: Move this to another part of the creation flow to prevent circular deps
    if (config._f === hooks.ISO_8601) {
        configFromISO(config);
        return;
    }
    if (config._f === hooks.RFC_2822) {
        configFromRFC2822(config);
        return;
    }
    config._a = [];
    getParsingFlags(config).empty = true;

    // This array is used to make a Date, either with `new Date` or `Date.UTC`
    var string = '' + config._i,
        i, parsedInput, tokens, token, skipped,
        stringLength = string.length,
        totalParsedInputLength = 0;

    tokens = expandFormat(config._f, config._locale).match(formattingTokens) || [];

    for (i = 0; i < tokens.length; i++) {
        token = tokens[i];
        parsedInput = (string.match(getParseRegexForToken(token, config)) || [])[0];
        // console.log('token', token, 'parsedInput', parsedInput,
        //         'regex', getParseRegexForToken(token, config));
        if (parsedInput) {
            skipped = string.substr(0, string.indexOf(parsedInput));
            if (skipped.length > 0) {
                getParsingFlags(config).unusedInput.push(skipped);
            }
            string = string.slice(string.indexOf(parsedInput) + parsedInput.length);
            totalParsedInputLength += parsedInput.length;
        }
        // don't parse if it's not a known token
        if (formatTokenFunctions[token]) {
            if (parsedInput) {
                getParsingFlags(config).empty = false;
            }
            else {
                getParsingFlags(config).unusedTokens.push(token);
            }
            addTimeToArrayFromToken(token, parsedInput, config);
        }
        else if (config._strict && !parsedInput) {
            getParsingFlags(config).unusedTokens.push(token);
        }
    }

    // add remaining unparsed input length to the string
    getParsingFlags(config).charsLeftOver = stringLength - totalParsedInputLength;
    if (string.length > 0) {
        getParsingFlags(config).unusedInput.push(string);
    }

    // clear _12h flag if hour is <= 12
    if (config._a[HOUR] <= 12 &&
        getParsingFlags(config).bigHour === true &&
        config._a[HOUR] > 0) {
        getParsingFlags(config).bigHour = undefined;
    }

    getParsingFlags(config).parsedDateParts = config._a.slice(0);
    getParsingFlags(config).meridiem = config._meridiem;
    // handle meridiem
    config._a[HOUR] = meridiemFixWrap(config._locale, config._a[HOUR], config._meridiem);

    configFromArray(config);
    checkOverflow(config);
}


function meridiemFixWrap (locale, hour, meridiem) {
    var isPm;

    if (meridiem == null) {
        // nothing to do
        return hour;
    }
    if (locale.meridiemHour != null) {
        return locale.meridiemHour(hour, meridiem);
    } else if (locale.isPM != null) {
        // Fallback
        isPm = locale.isPM(meridiem);
        if (isPm && hour < 12) {
            hour += 12;
        }
        if (!isPm && hour === 12) {
            hour = 0;
        }
        return hour;
    } else {
        // this is not supposed to happen
        return hour;
    }
}

// date from string and array of format strings
function configFromStringAndArray(config) {
    var tempConfig,
        bestMoment,

        scoreToBeat,
        i,
        currentScore;

    if (config._f.length === 0) {
        getParsingFlags(config).invalidFormat = true;
        config._d = new Date(NaN);
        return;
    }

    for (i = 0; i < config._f.length; i++) {
        currentScore = 0;
        tempConfig = copyConfig({}, config);
        if (config._useUTC != null) {
            tempConfig._useUTC = config._useUTC;
        }
        tempConfig._f = config._f[i];
        configFromStringAndFormat(tempConfig);

        if (!isValid(tempConfig)) {
            continue;
        }

        // if there is any input that was not parsed add a penalty for that format
        currentScore += getParsingFlags(tempConfig).charsLeftOver;

        //or tokens
        currentScore += getParsingFlags(tempConfig).unusedTokens.length * 10;

        getParsingFlags(tempConfig).score = currentScore;

        if (scoreToBeat == null || currentScore < scoreToBeat) {
            scoreToBeat = currentScore;
            bestMoment = tempConfig;
        }
    }

    extend(config, bestMoment || tempConfig);
}

function configFromObject(config) {
    if (config._d) {
        return;
    }

    var i = normalizeObjectUnits(config._i);
    config._a = map([i.year, i.month, i.day || i.date, i.hour, i.minute, i.second, i.millisecond], function (obj) {
        return obj && parseInt(obj, 10);
    });

    configFromArray(config);
}

function createFromConfig (config) {
    var res = new Moment(checkOverflow(prepareConfig(config)));
    if (res._nextDay) {
        // Adding is smart enough around DST
        res.add(1, 'd');
        res._nextDay = undefined;
    }

    return res;
}

function prepareConfig (config) {
    var input = config._i,
        format = config._f;

    config._locale = config._locale || getLocale(config._l);

    if (input === null || (format === undefined && input === '')) {
        return createInvalid({nullInput: true});
    }

    if (typeof input === 'string') {
        config._i = input = config._locale.preparse(input);
    }

    if (isMoment(input)) {
        return new Moment(checkOverflow(input));
    } else if (isDate(input)) {
        config._d = input;
    } else if (isArray(format)) {
        configFromStringAndArray(config);
    } else if (format) {
        configFromStringAndFormat(config);
    }  else {
        configFromInput(config);
    }

    if (!isValid(config)) {
        config._d = null;
    }

    return config;
}

function configFromInput(config) {
    var input = config._i;
    if (isUndefined(input)) {
        config._d = new Date(hooks.now());
    } else if (isDate(input)) {
        config._d = new Date(input.valueOf());
    } else if (typeof input === 'string') {
        configFromString(config);
    } else if (isArray(input)) {
        config._a = map(input.slice(0), function (obj) {
            return parseInt(obj, 10);
        });
        configFromArray(config);
    } else if (isObject(input)) {
        configFromObject(config);
    } else if (isNumber(input)) {
        // from milliseconds
        config._d = new Date(input);
    } else {
        hooks.createFromInputFallback(config);
    }
}

function createLocalOrUTC (input, format, locale, strict, isUTC) {
    var c = {};

    if (locale === true || locale === false) {
        strict = locale;
        locale = undefined;
    }

    if ((isObject(input) && isObjectEmpty(input)) ||
            (isArray(input) && input.length === 0)) {
        input = undefined;
    }
    // object construction must be done this way.
    // https://github.com/moment/moment/issues/1423
    c._isAMomentObject = true;
    c._useUTC = c._isUTC = isUTC;
    c._l = locale;
    c._i = input;
    c._f = format;
    c._strict = strict;

    return createFromConfig(c);
}

function createLocal (input, format, locale, strict) {
    return createLocalOrUTC(input, format, locale, strict, false);
}

var prototypeMin = deprecate(
    'moment().min is deprecated, use moment.max instead. http://momentjs.com/guides/#/warnings/min-max/',
    function () {
        var other = createLocal.apply(null, arguments);
        if (this.isValid() && other.isValid()) {
            return other < this ? this : other;
        } else {
            return createInvalid();
        }
    }
);

var prototypeMax = deprecate(
    'moment().max is deprecated, use moment.min instead. http://momentjs.com/guides/#/warnings/min-max/',
    function () {
        var other = createLocal.apply(null, arguments);
        if (this.isValid() && other.isValid()) {
            return other > this ? this : other;
        } else {
            return createInvalid();
        }
    }
);

// Pick a moment m from moments so that m[fn](other) is true for all
// other. This relies on the function fn to be transitive.
//
// moments should either be an array of moment objects or an array, whose
// first element is an array of moment objects.
function pickBy(fn, moments) {
    var res, i;
    if (moments.length === 1 && isArray(moments[0])) {
        moments = moments[0];
    }
    if (!moments.length) {
        return createLocal();
    }
    res = moments[0];
    for (i = 1; i < moments.length; ++i) {
        if (!moments[i].isValid() || moments[i][fn](res)) {
            res = moments[i];
        }
    }
    return res;
}

// TODO: Use [].sort instead?
function min () {
    var args = [].slice.call(arguments, 0);

    return pickBy('isBefore', args);
}

function max () {
    var args = [].slice.call(arguments, 0);

    return pickBy('isAfter', args);
}

var now = function () {
    return Date.now ? Date.now() : +(new Date());
};

var ordering = ['year', 'quarter', 'month', 'week', 'day', 'hour', 'minute', 'second', 'millisecond'];

function isDurationValid(m) {
    for (var key in m) {
        if (!(indexOf.call(ordering, key) !== -1 && (m[key] == null || !isNaN(m[key])))) {
            return false;
        }
    }

    var unitHasDecimal = false;
    for (var i = 0; i < ordering.length; ++i) {
        if (m[ordering[i]]) {
            if (unitHasDecimal) {
                return false; // only allow non-integers for smallest unit
            }
            if (parseFloat(m[ordering[i]]) !== toInt(m[ordering[i]])) {
                unitHasDecimal = true;
            }
        }
    }

    return true;
}

function isValid$1() {
    return this._isValid;
}

function createInvalid$1() {
    return createDuration(NaN);
}

function Duration (duration) {
    var normalizedInput = normalizeObjectUnits(duration),
        years = normalizedInput.year || 0,
        quarters = normalizedInput.quarter || 0,
        months = normalizedInput.month || 0,
        weeks = normalizedInput.week || 0,
        days = normalizedInput.day || 0,
        hours = normalizedInput.hour || 0,
        minutes = normalizedInput.minute || 0,
        seconds = normalizedInput.second || 0,
        milliseconds = normalizedInput.millisecond || 0;

    this._isValid = isDurationValid(normalizedInput);

    // representation for dateAddRemove
    this._milliseconds = +milliseconds +
        seconds * 1e3 + // 1000
        minutes * 6e4 + // 1000 * 60
        hours * 1000 * 60 * 60; //using 1000 * 60 * 60 instead of 36e5 to avoid floating point rounding errors https://github.com/moment/moment/issues/2978
    // Because of dateAddRemove treats 24 hours as different from a
    // day when working around DST, we need to store them separately
    this._days = +days +
        weeks * 7;
    // It is impossible to translate months into days without knowing
    // which months you are are talking about, so we have to store
    // it separately.
    this._months = +months +
        quarters * 3 +
        years * 12;

    this._data = {};

    this._locale = getLocale();

    this._bubble();
}

function isDuration (obj) {
    return obj instanceof Duration;
}

function absRound (number) {
    if (number < 0) {
        return Math.round(-1 * number) * -1;
    } else {
        return Math.round(number);
    }
}

// FORMATTING

function offset (token, separator) {
    addFormatToken(token, 0, 0, function () {
        var offset = this.utcOffset();
        var sign = '+';
        if (offset < 0) {
            offset = -offset;
            sign = '-';
        }
        return sign + zeroFill(~~(offset / 60), 2) + separator + zeroFill(~~(offset) % 60, 2);
    });
}

offset('Z', ':');
offset('ZZ', '');

// PARSING

addRegexToken('Z',  matchShortOffset);
addRegexToken('ZZ', matchShortOffset);
addParseToken(['Z', 'ZZ'], function (input, array, config) {
    config._useUTC = true;
    config._tzm = offsetFromString(matchShortOffset, input);
});

// HELPERS

// timezone chunker
// '+10:00' > ['10',  '00']
// '-1530'  > ['-15', '30']
var chunkOffset = /([\+\-]|\d\d)/gi;

function offsetFromString(matcher, string) {
    var matches = (string || '').match(matcher);

    if (matches === null) {
        return null;
    }

    var chunk   = matches[matches.length - 1] || [];
    var parts   = (chunk + '').match(chunkOffset) || ['-', 0, 0];
    var minutes = +(parts[1] * 60) + toInt(parts[2]);

    return minutes === 0 ?
      0 :
      parts[0] === '+' ? minutes : -minutes;
}

// Return a moment from input, that is local/utc/zone equivalent to model.
function cloneWithOffset(input, model) {
    var res, diff;
    if (model._isUTC) {
        res = model.clone();
        diff = (isMoment(input) || isDate(input) ? input.valueOf() : createLocal(input).valueOf()) - res.valueOf();
        // Use low-level api, because this fn is low-level api.
        res._d.setTime(res._d.valueOf() + diff);
        hooks.updateOffset(res, false);
        return res;
    } else {
        return createLocal(input).local();
    }
}

function getDateOffset (m) {
    // On Firefox.24 Date#getTimezoneOffset returns a floating point.
    // https://github.com/moment/moment/pull/1871
    return -Math.round(m._d.getTimezoneOffset() / 15) * 15;
}

// HOOKS

// This function will be called whenever a moment is mutated.
// It is intended to keep the offset in sync with the timezone.
hooks.updateOffset = function () {};

// MOMENTS

// keepLocalTime = true means only change the timezone, without
// affecting the local hour. So 5:31:26 +0300 --[utcOffset(2, true)]-->
// 5:31:26 +0200 It is possible that 5:31:26 doesn't exist with offset
// +0200, so we adjust the time as needed, to be valid.
//
// Keeping the time actually adds/subtracts (one hour)
// from the actual represented time. That is why we call updateOffset
// a second time. In case it wants us to change the offset again
// _changeInProgress == true case, then we have to adjust, because
// there is no such time in the given timezone.
function getSetOffset (input, keepLocalTime, keepMinutes) {
    var offset = this._offset || 0,
        localAdjust;
    if (!this.isValid()) {
        return input != null ? this : NaN;
    }
    if (input != null) {
        if (typeof input === 'string') {
            input = offsetFromString(matchShortOffset, input);
            if (input === null) {
                return this;
            }
        } else if (Math.abs(input) < 16 && !keepMinutes) {
            input = input * 60;
        }
        if (!this._isUTC && keepLocalTime) {
            localAdjust = getDateOffset(this);
        }
        this._offset = input;
        this._isUTC = true;
        if (localAdjust != null) {
            this.add(localAdjust, 'm');
        }
        if (offset !== input) {
            if (!keepLocalTime || this._changeInProgress) {
                addSubtract(this, createDuration(input - offset, 'm'), 1, false);
            } else if (!this._changeInProgress) {
                this._changeInProgress = true;
                hooks.updateOffset(this, true);
                this._changeInProgress = null;
            }
        }
        return this;
    } else {
        return this._isUTC ? offset : getDateOffset(this);
    }
}

function getSetZone (input, keepLocalTime) {
    if (input != null) {
        if (typeof input !== 'string') {
            input = -input;
        }

        this.utcOffset(input, keepLocalTime);

        return this;
    } else {
        return -this.utcOffset();
    }
}

function setOffsetToUTC (keepLocalTime) {
    return this.utcOffset(0, keepLocalTime);
}

function setOffsetToLocal (keepLocalTime) {
    if (this._isUTC) {
        this.utcOffset(0, keepLocalTime);
        this._isUTC = false;

        if (keepLocalTime) {
            this.subtract(getDateOffset(this), 'm');
        }
    }
    return this;
}

function setOffsetToParsedOffset () {
    if (this._tzm != null) {
        this.utcOffset(this._tzm, false, true);
    } else if (typeof this._i === 'string') {
        var tZone = offsetFromString(matchOffset, this._i);
        if (tZone != null) {
            this.utcOffset(tZone);
        }
        else {
            this.utcOffset(0, true);
        }
    }
    return this;
}

function hasAlignedHourOffset (input) {
    if (!this.isValid()) {
        return false;
    }
    input = input ? createLocal(input).utcOffset() : 0;

    return (this.utcOffset() - input) % 60 === 0;
}

function isDaylightSavingTime () {
    return (
        this.utcOffset() > this.clone().month(0).utcOffset() ||
        this.utcOffset() > this.clone().month(5).utcOffset()
    );
}

function isDaylightSavingTimeShifted () {
    if (!isUndefined(this._isDSTShifted)) {
        return this._isDSTShifted;
    }

    var c = {};

    copyConfig(c, this);
    c = prepareConfig(c);

    if (c._a) {
        var other = c._isUTC ? createUTC(c._a) : createLocal(c._a);
        this._isDSTShifted = this.isValid() &&
            compareArrays(c._a, other.toArray()) > 0;
    } else {
        this._isDSTShifted = false;
    }

    return this._isDSTShifted;
}

function isLocal () {
    return this.isValid() ? !this._isUTC : false;
}

function isUtcOffset () {
    return this.isValid() ? this._isUTC : false;
}

function isUtc () {
    return this.isValid() ? this._isUTC && this._offset === 0 : false;
}

// ASP.NET json date format regex
var aspNetRegex = /^(\-|\+)?(?:(\d*)[. ])?(\d+)\:(\d+)(?:\:(\d+)(\.\d*)?)?$/;

// from http://docs.closure-library.googlecode.com/git/closure_goog_date_date.js.source.html
// somewhat more in line with 4.4.3.2 2004 spec, but allows decimal anywhere
// and further modified to allow for strings containing both week and day
var isoRegex = /^(-|\+)?P(?:([-+]?[0-9,.]*)Y)?(?:([-+]?[0-9,.]*)M)?(?:([-+]?[0-9,.]*)W)?(?:([-+]?[0-9,.]*)D)?(?:T(?:([-+]?[0-9,.]*)H)?(?:([-+]?[0-9,.]*)M)?(?:([-+]?[0-9,.]*)S)?)?$/;

function createDuration (input, key) {
    var duration = input,
        // matching against regexp is expensive, do it on demand
        match = null,
        sign,
        ret,
        diffRes;

    if (isDuration(input)) {
        duration = {
            ms : input._milliseconds,
            d  : input._days,
            M  : input._months
        };
    } else if (isNumber(input)) {
        duration = {};
        if (key) {
            duration[key] = input;
        } else {
            duration.milliseconds = input;
        }
    } else if (!!(match = aspNetRegex.exec(input))) {
        sign = (match[1] === '-') ? -1 : 1;
        duration = {
            y  : 0,
            d  : toInt(match[DATE])                         * sign,
            h  : toInt(match[HOUR])                         * sign,
            m  : toInt(match[MINUTE])                       * sign,
            s  : toInt(match[SECOND])                       * sign,
            ms : toInt(absRound(match[MILLISECOND] * 1000)) * sign // the millisecond decimal point is included in the match
        };
    } else if (!!(match = isoRegex.exec(input))) {
        sign = (match[1] === '-') ? -1 : (match[1] === '+') ? 1 : 1;
        duration = {
            y : parseIso(match[2], sign),
            M : parseIso(match[3], sign),
            w : parseIso(match[4], sign),
            d : parseIso(match[5], sign),
            h : parseIso(match[6], sign),
            m : parseIso(match[7], sign),
            s : parseIso(match[8], sign)
        };
    } else if (duration == null) {// checks for null or undefined
        duration = {};
    } else if (typeof duration === 'object' && ('from' in duration || 'to' in duration)) {
        diffRes = momentsDifference(createLocal(duration.from), createLocal(duration.to));

        duration = {};
        duration.ms = diffRes.milliseconds;
        duration.M = diffRes.months;
    }

    ret = new Duration(duration);

    if (isDuration(input) && hasOwnProp(input, '_locale')) {
        ret._locale = input._locale;
    }

    return ret;
}

createDuration.fn = Duration.prototype;
createDuration.invalid = createInvalid$1;

function parseIso (inp, sign) {
    // We'd normally use ~~inp for this, but unfortunately it also
    // converts floats to ints.
    // inp may be undefined, so careful calling replace on it.
    var res = inp && parseFloat(inp.replace(',', '.'));
    // apply sign while we're at it
    return (isNaN(res) ? 0 : res) * sign;
}

function positiveMomentsDifference(base, other) {
    var res = {milliseconds: 0, months: 0};

    res.months = other.month() - base.month() +
        (other.year() - base.year()) * 12;
    if (base.clone().add(res.months, 'M').isAfter(other)) {
        --res.months;
    }

    res.milliseconds = +other - +(base.clone().add(res.months, 'M'));

    return res;
}

function momentsDifference(base, other) {
    var res;
    if (!(base.isValid() && other.isValid())) {
        return {milliseconds: 0, months: 0};
    }

    other = cloneWithOffset(other, base);
    if (base.isBefore(other)) {
        res = positiveMomentsDifference(base, other);
    } else {
        res = positiveMomentsDifference(other, base);
        res.milliseconds = -res.milliseconds;
        res.months = -res.months;
    }

    return res;
}

// TODO: remove 'name' arg after deprecation is removed
function createAdder(direction, name) {
    return function (val, period) {
        var dur, tmp;
        //invert the arguments, but complain about it
        if (period !== null && !isNaN(+period)) {
            deprecateSimple(name, 'moment().' + name  + '(period, number) is deprecated. Please use moment().' + name + '(number, period). ' +
            'See http://momentjs.com/guides/#/warnings/add-inverted-param/ for more info.');
            tmp = val; val = period; period = tmp;
        }

        val = typeof val === 'string' ? +val : val;
        dur = createDuration(val, period);
        addSubtract(this, dur, direction);
        return this;
    };
}

function addSubtract (mom, duration, isAdding, updateOffset) {
    var milliseconds = duration._milliseconds,
        days = absRound(duration._days),
        months = absRound(duration._months);

    if (!mom.isValid()) {
        // No op
        return;
    }

    updateOffset = updateOffset == null ? true : updateOffset;

    if (months) {
        setMonth(mom, get(mom, 'Month') + months * isAdding);
    }
    if (days) {
        set$1(mom, 'Date', get(mom, 'Date') + days * isAdding);
    }
    if (milliseconds) {
        mom._d.setTime(mom._d.valueOf() + milliseconds * isAdding);
    }
    if (updateOffset) {
        hooks.updateOffset(mom, days || months);
    }
}

var add      = createAdder(1, 'add');
var subtract = createAdder(-1, 'subtract');

function getCalendarFormat(myMoment, now) {
    var diff = myMoment.diff(now, 'days', true);
    return diff < -6 ? 'sameElse' :
            diff < -1 ? 'lastWeek' :
            diff < 0 ? 'lastDay' :
            diff < 1 ? 'sameDay' :
            diff < 2 ? 'nextDay' :
            diff < 7 ? 'nextWeek' : 'sameElse';
}

function calendar$1 (time, formats) {
    // We want to compare the start of today, vs this.
    // Getting start-of-today depends on whether we're local/utc/offset or not.
    var now = time || createLocal(),
        sod = cloneWithOffset(now, this).startOf('day'),
        format = hooks.calendarFormat(this, sod) || 'sameElse';

    var output = formats && (isFunction(formats[format]) ? formats[format].call(this, now) : formats[format]);

    return this.format(output || this.localeData().calendar(format, this, createLocal(now)));
}

function clone () {
    return new Moment(this);
}

function isAfter (input, units) {
    var localInput = isMoment(input) ? input : createLocal(input);
    if (!(this.isValid() && localInput.isValid())) {
        return false;
    }
    units = normalizeUnits(!isUndefined(units) ? units : 'millisecond');
    if (units === 'millisecond') {
        return this.valueOf() > localInput.valueOf();
    } else {
        return localInput.valueOf() < this.clone().startOf(units).valueOf();
    }
}

function isBefore (input, units) {
    var localInput = isMoment(input) ? input : createLocal(input);
    if (!(this.isValid() && localInput.isValid())) {
        return false;
    }
    units = normalizeUnits(!isUndefined(units) ? units : 'millisecond');
    if (units === 'millisecond') {
        return this.valueOf() < localInput.valueOf();
    } else {
        return this.clone().endOf(units).valueOf() < localInput.valueOf();
    }
}

function isBetween (from, to, units, inclusivity) {
    inclusivity = inclusivity || '()';
    return (inclusivity[0] === '(' ? this.isAfter(from, units) : !this.isBefore(from, units)) &&
        (inclusivity[1] === ')' ? this.isBefore(to, units) : !this.isAfter(to, units));
}

function isSame (input, units) {
    var localInput = isMoment(input) ? input : createLocal(input),
        inputMs;
    if (!(this.isValid() && localInput.isValid())) {
        return false;
    }
    units = normalizeUnits(units || 'millisecond');
    if (units === 'millisecond') {
        return this.valueOf() === localInput.valueOf();
    } else {
        inputMs = localInput.valueOf();
        return this.clone().startOf(units).valueOf() <= inputMs && inputMs <= this.clone().endOf(units).valueOf();
    }
}

function isSameOrAfter (input, units) {
    return this.isSame(input, units) || this.isAfter(input,units);
}

function isSameOrBefore (input, units) {
    return this.isSame(input, units) || this.isBefore(input,units);
}

function diff (input, units, asFloat) {
    var that,
        zoneDelta,
        delta, output;

    if (!this.isValid()) {
        return NaN;
    }

    that = cloneWithOffset(input, this);

    if (!that.isValid()) {
        return NaN;
    }

    zoneDelta = (that.utcOffset() - this.utcOffset()) * 6e4;

    units = normalizeUnits(units);

    switch (units) {
        case 'year': output = monthDiff(this, that) / 12; break;
        case 'month': output = monthDiff(this, that); break;
        case 'quarter': output = monthDiff(this, that) / 3; break;
        case 'second': output = (this - that) / 1e3; break; // 1000
        case 'minute': output = (this - that) / 6e4; break; // 1000 * 60
        case 'hour': output = (this - that) / 36e5; break; // 1000 * 60 * 60
        case 'day': output = (this - that - zoneDelta) / 864e5; break; // 1000 * 60 * 60 * 24, negate dst
        case 'week': output = (this - that - zoneDelta) / 6048e5; break; // 1000 * 60 * 60 * 24 * 7, negate dst
        default: output = this - that;
    }

    return asFloat ? output : absFloor(output);
}

function monthDiff (a, b) {
    // difference in months
    var wholeMonthDiff = ((b.year() - a.year()) * 12) + (b.month() - a.month()),
        // b is in (anchor - 1 month, anchor + 1 month)
        anchor = a.clone().add(wholeMonthDiff, 'months'),
        anchor2, adjust;

    if (b - anchor < 0) {
        anchor2 = a.clone().add(wholeMonthDiff - 1, 'months');
        // linear across the month
        adjust = (b - anchor) / (anchor - anchor2);
    } else {
        anchor2 = a.clone().add(wholeMonthDiff + 1, 'months');
        // linear across the month
        adjust = (b - anchor) / (anchor2 - anchor);
    }

    //check for negative zero, return zero if negative zero
    return -(wholeMonthDiff + adjust) || 0;
}

hooks.defaultFormat = 'YYYY-MM-DDTHH:mm:ssZ';
hooks.defaultFormatUtc = 'YYYY-MM-DDTHH:mm:ss[Z]';

function toString () {
    return this.clone().locale('en').format('ddd MMM DD YYYY HH:mm:ss [GMT]ZZ');
}

function toISOString(keepOffset) {
    if (!this.isValid()) {
        return null;
    }
    var utc = keepOffset !== true;
    var m = utc ? this.clone().utc() : this;
    if (m.year() < 0 || m.year() > 9999) {
        return formatMoment(m, utc ? 'YYYYYY-MM-DD[T]HH:mm:ss.SSS[Z]' : 'YYYYYY-MM-DD[T]HH:mm:ss.SSSZ');
    }
    if (isFunction(Date.prototype.toISOString)) {
        // native implementation is ~50x faster, use it when we can
        if (utc) {
            return this.toDate().toISOString();
        } else {
            return new Date(this._d.valueOf()).toISOString().replace('Z', formatMoment(m, 'Z'));
        }
    }
    return formatMoment(m, utc ? 'YYYY-MM-DD[T]HH:mm:ss.SSS[Z]' : 'YYYY-MM-DD[T]HH:mm:ss.SSSZ');
}

/**
 * Return a human readable representation of a moment that can
 * also be evaluated to get a new moment which is the same
 *
 * @link https://nodejs.org/dist/latest/docs/api/util.html#util_custom_inspect_function_on_objects
 */
function inspect () {
    if (!this.isValid()) {
        return 'moment.invalid(/* ' + this._i + ' */)';
    }
    var func = 'moment';
    var zone = '';
    if (!this.isLocal()) {
        func = this.utcOffset() === 0 ? 'moment.utc' : 'moment.parseZone';
        zone = 'Z';
    }
    var prefix = '[' + func + '("]';
    var year = (0 <= this.year() && this.year() <= 9999) ? 'YYYY' : 'YYYYYY';
    var datetime = '-MM-DD[T]HH:mm:ss.SSS';
    var suffix = zone + '[")]';

    return this.format(prefix + year + datetime + suffix);
}

function format (inputString) {
    if (!inputString) {
        inputString = this.isUtc() ? hooks.defaultFormatUtc : hooks.defaultFormat;
    }
    var output = formatMoment(this, inputString);
    return this.localeData().postformat(output);
}

function from (time, withoutSuffix) {
    if (this.isValid() &&
            ((isMoment(time) && time.isValid()) ||
             createLocal(time).isValid())) {
        return createDuration({to: this, from: time}).locale(this.locale()).humanize(!withoutSuffix);
    } else {
        return this.localeData().invalidDate();
    }
}

function fromNow (withoutSuffix) {
    return this.from(createLocal(), withoutSuffix);
}

function to (time, withoutSuffix) {
    if (this.isValid() &&
            ((isMoment(time) && time.isValid()) ||
             createLocal(time).isValid())) {
        return createDuration({from: this, to: time}).locale(this.locale()).humanize(!withoutSuffix);
    } else {
        return this.localeData().invalidDate();
    }
}

function toNow (withoutSuffix) {
    return this.to(createLocal(), withoutSuffix);
}

// If passed a locale key, it will set the locale for this
// instance.  Otherwise, it will return the locale configuration
// variables for this instance.
function locale (key) {
    var newLocaleData;

    if (key === undefined) {
        return this._locale._abbr;
    } else {
        newLocaleData = getLocale(key);
        if (newLocaleData != null) {
            this._locale = newLocaleData;
        }
        return this;
    }
}

var lang = deprecate(
    'moment().lang() is deprecated. Instead, use moment().localeData() to get the language configuration. Use moment().locale() to change languages.',
    function (key) {
        if (key === undefined) {
            return this.localeData();
        } else {
            return this.locale(key);
        }
    }
);

function localeData () {
    return this._locale;
}

function startOf (units) {
    units = normalizeUnits(units);
    // the following switch intentionally omits break keywords
    // to utilize falling through the cases.
    switch (units) {
        case 'year':
            this.month(0);
            /* falls through */
        case 'quarter':
        case 'month':
            this.date(1);
            /* falls through */
        case 'week':
        case 'isoWeek':
        case 'day':
        case 'date':
            this.hours(0);
            /* falls through */
        case 'hour':
            this.minutes(0);
            /* falls through */
        case 'minute':
            this.seconds(0);
            /* falls through */
        case 'second':
            this.milliseconds(0);
    }

    // weeks are a special case
    if (units === 'week') {
        this.weekday(0);
    }
    if (units === 'isoWeek') {
        this.isoWeekday(1);
    }

    // quarters are also special
    if (units === 'quarter') {
        this.month(Math.floor(this.month() / 3) * 3);
    }

    return this;
}

function endOf (units) {
    units = normalizeUnits(units);
    if (units === undefined || units === 'millisecond') {
        return this;
    }

    // 'date' is an alias for 'day', so it should be considered as such.
    if (units === 'date') {
        units = 'day';
    }

    return this.startOf(units).add(1, (units === 'isoWeek' ? 'week' : units)).subtract(1, 'ms');
}

function valueOf () {
    return this._d.valueOf() - ((this._offset || 0) * 60000);
}

function unix () {
    return Math.floor(this.valueOf() / 1000);
}

function toDate () {
    return new Date(this.valueOf());
}

function toArray () {
    var m = this;
    return [m.year(), m.month(), m.date(), m.hour(), m.minute(), m.second(), m.millisecond()];
}

function toObject () {
    var m = this;
    return {
        years: m.year(),
        months: m.month(),
        date: m.date(),
        hours: m.hours(),
        minutes: m.minutes(),
        seconds: m.seconds(),
        milliseconds: m.milliseconds()
    };
}

function toJSON () {
    // new Date(NaN).toJSON() === null
    return this.isValid() ? this.toISOString() : null;
}

function isValid$2 () {
    return isValid(this);
}

function parsingFlags () {
    return extend({}, getParsingFlags(this));
}

function invalidAt () {
    return getParsingFlags(this).overflow;
}

function creationData() {
    return {
        input: this._i,
        format: this._f,
        locale: this._locale,
        isUTC: this._isUTC,
        strict: this._strict
    };
}

// FORMATTING

addFormatToken(0, ['gg', 2], 0, function () {
    return this.weekYear() % 100;
});

addFormatToken(0, ['GG', 2], 0, function () {
    return this.isoWeekYear() % 100;
});

function addWeekYearFormatToken (token, getter) {
    addFormatToken(0, [token, token.length], 0, getter);
}

addWeekYearFormatToken('gggg',     'weekYear');
addWeekYearFormatToken('ggggg',    'weekYear');
addWeekYearFormatToken('GGGG',  'isoWeekYear');
addWeekYearFormatToken('GGGGG', 'isoWeekYear');

// ALIASES

addUnitAlias('weekYear', 'gg');
addUnitAlias('isoWeekYear', 'GG');

// PRIORITY

addUnitPriority('weekYear', 1);
addUnitPriority('isoWeekYear', 1);


// PARSING

addRegexToken('G',      matchSigned);
addRegexToken('g',      matchSigned);
addRegexToken('GG',     match1to2, match2);
addRegexToken('gg',     match1to2, match2);
addRegexToken('GGGG',   match1to4, match4);
addRegexToken('gggg',   match1to4, match4);
addRegexToken('GGGGG',  match1to6, match6);
addRegexToken('ggggg',  match1to6, match6);

addWeekParseToken(['gggg', 'ggggg', 'GGGG', 'GGGGG'], function (input, week, config, token) {
    week[token.substr(0, 2)] = toInt(input);
});

addWeekParseToken(['gg', 'GG'], function (input, week, config, token) {
    week[token] = hooks.parseTwoDigitYear(input);
});

// MOMENTS

function getSetWeekYear (input) {
    return getSetWeekYearHelper.call(this,
            input,
            this.week(),
            this.weekday(),
            this.localeData()._week.dow,
            this.localeData()._week.doy);
}

function getSetISOWeekYear (input) {
    return getSetWeekYearHelper.call(this,
            input, this.isoWeek(), this.isoWeekday(), 1, 4);
}

function getISOWeeksInYear () {
    return weeksInYear(this.year(), 1, 4);
}

function getWeeksInYear () {
    var weekInfo = this.localeData()._week;
    return weeksInYear(this.year(), weekInfo.dow, weekInfo.doy);
}

function getSetWeekYearHelper(input, week, weekday, dow, doy) {
    var weeksTarget;
    if (input == null) {
        return weekOfYear(this, dow, doy).year;
    } else {
        weeksTarget = weeksInYear(input, dow, doy);
        if (week > weeksTarget) {
            week = weeksTarget;
        }
        return setWeekAll.call(this, input, week, weekday, dow, doy);
    }
}

function setWeekAll(weekYear, week, weekday, dow, doy) {
    var dayOfYearData = dayOfYearFromWeeks(weekYear, week, weekday, dow, doy),
        date = createUTCDate(dayOfYearData.year, 0, dayOfYearData.dayOfYear);

    this.year(date.getUTCFullYear());
    this.month(date.getUTCMonth());
    this.date(date.getUTCDate());
    return this;
}

// FORMATTING

addFormatToken('Q', 0, 'Qo', 'quarter');

// ALIASES

addUnitAlias('quarter', 'Q');

// PRIORITY

addUnitPriority('quarter', 7);

// PARSING

addRegexToken('Q', match1);
addParseToken('Q', function (input, array) {
    array[MONTH] = (toInt(input) - 1) * 3;
});

// MOMENTS

function getSetQuarter (input) {
    return input == null ? Math.ceil((this.month() + 1) / 3) : this.month((input - 1) * 3 + this.month() % 3);
}

// FORMATTING

addFormatToken('D', ['DD', 2], 'Do', 'date');

// ALIASES

addUnitAlias('date', 'D');

// PRIOROITY
addUnitPriority('date', 9);

// PARSING

addRegexToken('D',  match1to2);
addRegexToken('DD', match1to2, match2);
addRegexToken('Do', function (isStrict, locale) {
    // TODO: Remove "ordinalParse" fallback in next major release.
    return isStrict ?
      (locale._dayOfMonthOrdinalParse || locale._ordinalParse) :
      locale._dayOfMonthOrdinalParseLenient;
});

addParseToken(['D', 'DD'], DATE);
addParseToken('Do', function (input, array) {
    array[DATE] = toInt(input.match(match1to2)[0]);
});

// MOMENTS

var getSetDayOfMonth = makeGetSet('Date', true);

// FORMATTING

addFormatToken('DDD', ['DDDD', 3], 'DDDo', 'dayOfYear');

// ALIASES

addUnitAlias('dayOfYear', 'DDD');

// PRIORITY
addUnitPriority('dayOfYear', 4);

// PARSING

addRegexToken('DDD',  match1to3);
addRegexToken('DDDD', match3);
addParseToken(['DDD', 'DDDD'], function (input, array, config) {
    config._dayOfYear = toInt(input);
});

// HELPERS

// MOMENTS

function getSetDayOfYear (input) {
    var dayOfYear = Math.round((this.clone().startOf('day') - this.clone().startOf('year')) / 864e5) + 1;
    return input == null ? dayOfYear : this.add((input - dayOfYear), 'd');
}

// FORMATTING

addFormatToken('m', ['mm', 2], 0, 'minute');

// ALIASES

addUnitAlias('minute', 'm');

// PRIORITY

addUnitPriority('minute', 14);

// PARSING

addRegexToken('m',  match1to2);
addRegexToken('mm', match1to2, match2);
addParseToken(['m', 'mm'], MINUTE);

// MOMENTS

var getSetMinute = makeGetSet('Minutes', false);

// FORMATTING

addFormatToken('s', ['ss', 2], 0, 'second');

// ALIASES

addUnitAlias('second', 's');

// PRIORITY

addUnitPriority('second', 15);

// PARSING

addRegexToken('s',  match1to2);
addRegexToken('ss', match1to2, match2);
addParseToken(['s', 'ss'], SECOND);

// MOMENTS

var getSetSecond = makeGetSet('Seconds', false);

// FORMATTING

addFormatToken('S', 0, 0, function () {
    return ~~(this.millisecond() / 100);
});

addFormatToken(0, ['SS', 2], 0, function () {
    return ~~(this.millisecond() / 10);
});

addFormatToken(0, ['SSS', 3], 0, 'millisecond');
addFormatToken(0, ['SSSS', 4], 0, function () {
    return this.millisecond() * 10;
});
addFormatToken(0, ['SSSSS', 5], 0, function () {
    return this.millisecond() * 100;
});
addFormatToken(0, ['SSSSSS', 6], 0, function () {
    return this.millisecond() * 1000;
});
addFormatToken(0, ['SSSSSSS', 7], 0, function () {
    return this.millisecond() * 10000;
});
addFormatToken(0, ['SSSSSSSS', 8], 0, function () {
    return this.millisecond() * 100000;
});
addFormatToken(0, ['SSSSSSSSS', 9], 0, function () {
    return this.millisecond() * 1000000;
});


// ALIASES

addUnitAlias('millisecond', 'ms');

// PRIORITY

addUnitPriority('millisecond', 16);

// PARSING

addRegexToken('S',    match1to3, match1);
addRegexToken('SS',   match1to3, match2);
addRegexToken('SSS',  match1to3, match3);

var token;
for (token = 'SSSS'; token.length <= 9; token += 'S') {
    addRegexToken(token, matchUnsigned);
}

function parseMs(input, array) {
    array[MILLISECOND] = toInt(('0.' + input) * 1000);
}

for (token = 'S'; token.length <= 9; token += 'S') {
    addParseToken(token, parseMs);
}
// MOMENTS

var getSetMillisecond = makeGetSet('Milliseconds', false);

// FORMATTING

addFormatToken('z',  0, 0, 'zoneAbbr');
addFormatToken('zz', 0, 0, 'zoneName');

// MOMENTS

function getZoneAbbr () {
    return this._isUTC ? 'UTC' : '';
}

function getZoneName () {
    return this._isUTC ? 'Coordinated Universal Time' : '';
}

var proto = Moment.prototype;

proto.add               = add;
proto.calendar          = calendar$1;
proto.clone             = clone;
proto.diff              = diff;
proto.endOf             = endOf;
proto.format            = format;
proto.from              = from;
proto.fromNow           = fromNow;
proto.to                = to;
proto.toNow             = toNow;
proto.get               = stringGet;
proto.invalidAt         = invalidAt;
proto.isAfter           = isAfter;
proto.isBefore          = isBefore;
proto.isBetween         = isBetween;
proto.isSame            = isSame;
proto.isSameOrAfter     = isSameOrAfter;
proto.isSameOrBefore    = isSameOrBefore;
proto.isValid           = isValid$2;
proto.lang              = lang;
proto.locale            = locale;
proto.localeData        = localeData;
proto.max               = prototypeMax;
proto.min               = prototypeMin;
proto.parsingFlags      = parsingFlags;
proto.set               = stringSet;
proto.startOf           = startOf;
proto.subtract          = subtract;
proto.toArray           = toArray;
proto.toObject          = toObject;
proto.toDate            = toDate;
proto.toISOString       = toISOString;
proto.inspect           = inspect;
proto.toJSON            = toJSON;
proto.toString          = toString;
proto.unix              = unix;
proto.valueOf           = valueOf;
proto.creationData      = creationData;

// Year
proto.year       = getSetYear;
proto.isLeapYear = getIsLeapYear;

// Week Year
proto.weekYear    = getSetWeekYear;
proto.isoWeekYear = getSetISOWeekYear;

// Quarter
proto.quarter = proto.quarters = getSetQuarter;

// Month
proto.month       = getSetMonth;
proto.daysInMonth = getDaysInMonth;

// Week
proto.week           = proto.weeks        = getSetWeek;
proto.isoWeek        = proto.isoWeeks     = getSetISOWeek;
proto.weeksInYear    = getWeeksInYear;
proto.isoWeeksInYear = getISOWeeksInYear;

// Day
proto.date       = getSetDayOfMonth;
proto.day        = proto.days             = getSetDayOfWeek;
proto.weekday    = getSetLocaleDayOfWeek;
proto.isoWeekday = getSetISODayOfWeek;
proto.dayOfYear  = getSetDayOfYear;

// Hour
proto.hour = proto.hours = getSetHour;

// Minute
proto.minute = proto.minutes = getSetMinute;

// Second
proto.second = proto.seconds = getSetSecond;

// Millisecond
proto.millisecond = proto.milliseconds = getSetMillisecond;

// Offset
proto.utcOffset            = getSetOffset;
proto.utc                  = setOffsetToUTC;
proto.local                = setOffsetToLocal;
proto.parseZone            = setOffsetToParsedOffset;
proto.hasAlignedHourOffset = hasAlignedHourOffset;
proto.isDST                = isDaylightSavingTime;
proto.isLocal              = isLocal;
proto.isUtcOffset          = isUtcOffset;
proto.isUtc                = isUtc;
proto.isUTC                = isUtc;

// Timezone
proto.zoneAbbr = getZoneAbbr;
proto.zoneName = getZoneName;

// Deprecations
proto.dates  = deprecate('dates accessor is deprecated. Use date instead.', getSetDayOfMonth);
proto.months = deprecate('months accessor is deprecated. Use month instead', getSetMonth);
proto.years  = deprecate('years accessor is deprecated. Use year instead', getSetYear);
proto.zone   = deprecate('moment().zone is deprecated, use moment().utcOffset instead. http://momentjs.com/guides/#/warnings/zone/', getSetZone);
proto.isDSTShifted = deprecate('isDSTShifted is deprecated. See http://momentjs.com/guides/#/warnings/dst-shifted/ for more information', isDaylightSavingTimeShifted);

function createUnix (input) {
    return createLocal(input * 1000);
}

function createInZone () {
    return createLocal.apply(null, arguments).parseZone();
}

function preParsePostFormat (string) {
    return string;
}

var proto$1 = Locale.prototype;

proto$1.calendar        = calendar;
proto$1.longDateFormat  = longDateFormat;
proto$1.invalidDate     = invalidDate;
proto$1.ordinal         = ordinal;
proto$1.preparse        = preParsePostFormat;
proto$1.postformat      = preParsePostFormat;
proto$1.relativeTime    = relativeTime;
proto$1.pastFuture      = pastFuture;
proto$1.set             = set;

// Month
proto$1.months            =        localeMonths;
proto$1.monthsShort       =        localeMonthsShort;
proto$1.monthsParse       =        localeMonthsParse;
proto$1.monthsRegex       = monthsRegex;
proto$1.monthsShortRegex  = monthsShortRegex;

// Week
proto$1.week = localeWeek;
proto$1.firstDayOfYear = localeFirstDayOfYear;
proto$1.firstDayOfWeek = localeFirstDayOfWeek;

// Day of Week
proto$1.weekdays       =        localeWeekdays;
proto$1.weekdaysMin    =        localeWeekdaysMin;
proto$1.weekdaysShort  =        localeWeekdaysShort;
proto$1.weekdaysParse  =        localeWeekdaysParse;

proto$1.weekdaysRegex       =        weekdaysRegex;
proto$1.weekdaysShortRegex  =        weekdaysShortRegex;
proto$1.weekdaysMinRegex    =        weekdaysMinRegex;

// Hours
proto$1.isPM = localeIsPM;
proto$1.meridiem = localeMeridiem;

function get$1 (format, index, field, setter) {
    var locale = getLocale();
    var utc = createUTC().set(setter, index);
    return locale[field](utc, format);
}

function listMonthsImpl (format, index, field) {
    if (isNumber(format)) {
        index = format;
        format = undefined;
    }

    format = format || '';

    if (index != null) {
        return get$1(format, index, field, 'month');
    }

    var i;
    var out = [];
    for (i = 0; i < 12; i++) {
        out[i] = get$1(format, i, field, 'month');
    }
    return out;
}

// ()
// (5)
// (fmt, 5)
// (fmt)
// (true)
// (true, 5)
// (true, fmt, 5)
// (true, fmt)
function listWeekdaysImpl (localeSorted, format, index, field) {
    if (typeof localeSorted === 'boolean') {
        if (isNumber(format)) {
            index = format;
            format = undefined;
        }

        format = format || '';
    } else {
        format = localeSorted;
        index = format;
        localeSorted = false;

        if (isNumber(format)) {
            index = format;
            format = undefined;
        }

        format = format || '';
    }

    var locale = getLocale(),
        shift = localeSorted ? locale._week.dow : 0;

    if (index != null) {
        return get$1(format, (index + shift) % 7, field, 'day');
    }

    var i;
    var out = [];
    for (i = 0; i < 7; i++) {
        out[i] = get$1(format, (i + shift) % 7, field, 'day');
    }
    return out;
}

function listMonths (format, index) {
    return listMonthsImpl(format, index, 'months');
}

function listMonthsShort (format, index) {
    return listMonthsImpl(format, index, 'monthsShort');
}

function listWeekdays (localeSorted, format, index) {
    return listWeekdaysImpl(localeSorted, format, index, 'weekdays');
}

function listWeekdaysShort (localeSorted, format, index) {
    return listWeekdaysImpl(localeSorted, format, index, 'weekdaysShort');
}

function listWeekdaysMin (localeSorted, format, index) {
    return listWeekdaysImpl(localeSorted, format, index, 'weekdaysMin');
}

getSetGlobalLocale('en', {
    dayOfMonthOrdinalParse: /\d{1,2}(th|st|nd|rd)/,
    ordinal : function (number) {
        var b = number % 10,
            output = (toInt(number % 100 / 10) === 1) ? 'th' :
            (b === 1) ? 'st' :
            (b === 2) ? 'nd' :
            (b === 3) ? 'rd' : 'th';
        return number + output;
    }
});

// Side effect imports
hooks.lang = deprecate('moment.lang is deprecated. Use moment.locale instead.', getSetGlobalLocale);
hooks.langData = deprecate('moment.langData is deprecated. Use moment.localeData instead.', getLocale);

var mathAbs = Math.abs;

function abs () {
    var data           = this._data;

    this._milliseconds = mathAbs(this._milliseconds);
    this._days         = mathAbs(this._days);
    this._months       = mathAbs(this._months);

    data.milliseconds  = mathAbs(data.milliseconds);
    data.seconds       = mathAbs(data.seconds);
    data.minutes       = mathAbs(data.minutes);
    data.hours         = mathAbs(data.hours);
    data.months        = mathAbs(data.months);
    data.years         = mathAbs(data.years);

    return this;
}

function addSubtract$1 (duration, input, value, direction) {
    var other = createDuration(input, value);

    duration._milliseconds += direction * other._milliseconds;
    duration._days         += direction * other._days;
    duration._months       += direction * other._months;

    return duration._bubble();
}

// supports only 2.0-style add(1, 's') or add(duration)
function add$1 (input, value) {
    return addSubtract$1(this, input, value, 1);
}

// supports only 2.0-style subtract(1, 's') or subtract(duration)
function subtract$1 (input, value) {
    return addSubtract$1(this, input, value, -1);
}

function absCeil (number) {
    if (number < 0) {
        return Math.floor(number);
    } else {
        return Math.ceil(number);
    }
}

function bubble () {
    var milliseconds = this._milliseconds;
    var days         = this._days;
    var months       = this._months;
    var data         = this._data;
    var seconds, minutes, hours, years, monthsFromDays;

    // if we have a mix of positive and negative values, bubble down first
    // check: https://github.com/moment/moment/issues/2166
    if (!((milliseconds >= 0 && days >= 0 && months >= 0) ||
            (milliseconds <= 0 && days <= 0 && months <= 0))) {
        milliseconds += absCeil(monthsToDays(months) + days) * 864e5;
        days = 0;
        months = 0;
    }

    // The following code bubbles up values, see the tests for
    // examples of what that means.
    data.milliseconds = milliseconds % 1000;

    seconds           = absFloor(milliseconds / 1000);
    data.seconds      = seconds % 60;

    minutes           = absFloor(seconds / 60);
    data.minutes      = minutes % 60;

    hours             = absFloor(minutes / 60);
    data.hours        = hours % 24;

    days += absFloor(hours / 24);

    // convert days to months
    monthsFromDays = absFloor(daysToMonths(days));
    months += monthsFromDays;
    days -= absCeil(monthsToDays(monthsFromDays));

    // 12 months -> 1 year
    years = absFloor(months / 12);
    months %= 12;

    data.days   = days;
    data.months = months;
    data.years  = years;

    return this;
}

function daysToMonths (days) {
    // 400 years have 146097 days (taking into account leap year rules)
    // 400 years have 12 months === 4800
    return days * 4800 / 146097;
}

function monthsToDays (months) {
    // the reverse of daysToMonths
    return months * 146097 / 4800;
}

function as (units) {
    if (!this.isValid()) {
        return NaN;
    }
    var days;
    var months;
    var milliseconds = this._milliseconds;

    units = normalizeUnits(units);

    if (units === 'month' || units === 'year') {
        days   = this._days   + milliseconds / 864e5;
        months = this._months + daysToMonths(days);
        return units === 'month' ? months : months / 12;
    } else {
        // handle milliseconds separately because of floating point math errors (issue #1867)
        days = this._days + Math.round(monthsToDays(this._months));
        switch (units) {
            case 'week'   : return days / 7     + milliseconds / 6048e5;
            case 'day'    : return days         + milliseconds / 864e5;
            case 'hour'   : return days * 24    + milliseconds / 36e5;
            case 'minute' : return days * 1440  + milliseconds / 6e4;
            case 'second' : return days * 86400 + milliseconds / 1000;
            // Math.floor prevents floating point math errors here
            case 'millisecond': return Math.floor(days * 864e5) + milliseconds;
            default: throw new Error('Unknown unit ' + units);
        }
    }
}

// TODO: Use this.as('ms')?
function valueOf$1 () {
    if (!this.isValid()) {
        return NaN;
    }
    return (
        this._milliseconds +
        this._days * 864e5 +
        (this._months % 12) * 2592e6 +
        toInt(this._months / 12) * 31536e6
    );
}

function makeAs (alias) {
    return function () {
        return this.as(alias);
    };
}

var asMilliseconds = makeAs('ms');
var asSeconds      = makeAs('s');
var asMinutes      = makeAs('m');
var asHours        = makeAs('h');
var asDays         = makeAs('d');
var asWeeks        = makeAs('w');
var asMonths       = makeAs('M');
var asYears        = makeAs('y');

function clone$1 () {
    return createDuration(this);
}

function get$2 (units) {
    units = normalizeUnits(units);
    return this.isValid() ? this[units + 's']() : NaN;
}

function makeGetter(name) {
    return function () {
        return this.isValid() ? this._data[name] : NaN;
    };
}

var milliseconds = makeGetter('milliseconds');
var seconds      = makeGetter('seconds');
var minutes      = makeGetter('minutes');
var hours        = makeGetter('hours');
var days         = makeGetter('days');
var months       = makeGetter('months');
var years        = makeGetter('years');

function weeks () {
    return absFloor(this.days() / 7);
}

var round = Math.round;
var thresholds = {
    ss: 44,         // a few seconds to seconds
    s : 45,         // seconds to minute
    m : 45,         // minutes to hour
    h : 22,         // hours to day
    d : 26,         // days to month
    M : 11          // months to year
};

// helper function for moment.fn.from, moment.fn.fromNow, and moment.duration.fn.humanize
function substituteTimeAgo(string, number, withoutSuffix, isFuture, locale) {
    return locale.relativeTime(number || 1, !!withoutSuffix, string, isFuture);
}

function relativeTime$1 (posNegDuration, withoutSuffix, locale) {
    var duration = createDuration(posNegDuration).abs();
    var seconds  = round(duration.as('s'));
    var minutes  = round(duration.as('m'));
    var hours    = round(duration.as('h'));
    var days     = round(duration.as('d'));
    var months   = round(duration.as('M'));
    var years    = round(duration.as('y'));

    var a = seconds <= thresholds.ss && ['s', seconds]  ||
            seconds < thresholds.s   && ['ss', seconds] ||
            minutes <= 1             && ['m']           ||
            minutes < thresholds.m   && ['mm', minutes] ||
            hours   <= 1             && ['h']           ||
            hours   < thresholds.h   && ['hh', hours]   ||
            days    <= 1             && ['d']           ||
            days    < thresholds.d   && ['dd', days]    ||
            months  <= 1             && ['M']           ||
            months  < thresholds.M   && ['MM', months]  ||
            years   <= 1             && ['y']           || ['yy', years];

    a[2] = withoutSuffix;
    a[3] = +posNegDuration > 0;
    a[4] = locale;
    return substituteTimeAgo.apply(null, a);
}

// This function allows you to set the rounding function for relative time strings
function getSetRelativeTimeRounding (roundingFunction) {
    if (roundingFunction === undefined) {
        return round;
    }
    if (typeof(roundingFunction) === 'function') {
        round = roundingFunction;
        return true;
    }
    return false;
}

// This function allows you to set a threshold for relative time strings
function getSetRelativeTimeThreshold (threshold, limit) {
    if (thresholds[threshold] === undefined) {
        return false;
    }
    if (limit === undefined) {
        return thresholds[threshold];
    }
    thresholds[threshold] = limit;
    if (threshold === 's') {
        thresholds.ss = limit - 1;
    }
    return true;
}

function humanize (withSuffix) {
    if (!this.isValid()) {
        return this.localeData().invalidDate();
    }

    var locale = this.localeData();
    var output = relativeTime$1(this, !withSuffix, locale);

    if (withSuffix) {
        output = locale.pastFuture(+this, output);
    }

    return locale.postformat(output);
}

var abs$1 = Math.abs;

function sign(x) {
    return ((x > 0) - (x < 0)) || +x;
}

function toISOString$1() {
    // for ISO strings we do not use the normal bubbling rules:
    //  * milliseconds bubble up until they become hours
    //  * days do not bubble at all
    //  * months bubble up until they become years
    // This is because there is no context-free conversion between hours and days
    // (think of clock changes)
    // and also not between days and months (28-31 days per month)
    if (!this.isValid()) {
        return this.localeData().invalidDate();
    }

    var seconds = abs$1(this._milliseconds) / 1000;
    var days         = abs$1(this._days);
    var months       = abs$1(this._months);
    var minutes, hours, years;

    // 3600 seconds -> 60 minutes -> 1 hour
    minutes           = absFloor(seconds / 60);
    hours             = absFloor(minutes / 60);
    seconds %= 60;
    minutes %= 60;

    // 12 months -> 1 year
    years  = absFloor(months / 12);
    months %= 12;


    // inspired by https://github.com/dordille/moment-isoduration/blob/master/moment.isoduration.js
    var Y = years;
    var M = months;
    var D = days;
    var h = hours;
    var m = minutes;
    var s = seconds ? seconds.toFixed(3).replace(/\.?0+$/, '') : '';
    var total = this.asSeconds();

    if (!total) {
        // this is the same as C#'s (Noda) and python (isodate)...
        // but not other JS (goog.date)
        return 'P0D';
    }

    var totalSign = total < 0 ? '-' : '';
    var ymSign = sign(this._months) !== sign(total) ? '-' : '';
    var daysSign = sign(this._days) !== sign(total) ? '-' : '';
    var hmsSign = sign(this._milliseconds) !== sign(total) ? '-' : '';

    return totalSign + 'P' +
        (Y ? ymSign + Y + 'Y' : '') +
        (M ? ymSign + M + 'M' : '') +
        (D ? daysSign + D + 'D' : '') +
        ((h || m || s) ? 'T' : '') +
        (h ? hmsSign + h + 'H' : '') +
        (m ? hmsSign + m + 'M' : '') +
        (s ? hmsSign + s + 'S' : '');
}

var proto$2 = Duration.prototype;

proto$2.isValid        = isValid$1;
proto$2.abs            = abs;
proto$2.add            = add$1;
proto$2.subtract       = subtract$1;
proto$2.as             = as;
proto$2.asMilliseconds = asMilliseconds;
proto$2.asSeconds      = asSeconds;
proto$2.asMinutes      = asMinutes;
proto$2.asHours        = asHours;
proto$2.asDays         = asDays;
proto$2.asWeeks        = asWeeks;
proto$2.asMonths       = asMonths;
proto$2.asYears        = asYears;
proto$2.valueOf        = valueOf$1;
proto$2._bubble        = bubble;
proto$2.clone          = clone$1;
proto$2.get            = get$2;
proto$2.milliseconds   = milliseconds;
proto$2.seconds        = seconds;
proto$2.minutes        = minutes;
proto$2.hours          = hours;
proto$2.days           = days;
proto$2.weeks          = weeks;
proto$2.months         = months;
proto$2.years          = years;
proto$2.humanize       = humanize;
proto$2.toISOString    = toISOString$1;
proto$2.toString       = toISOString$1;
proto$2.toJSON         = toISOString$1;
proto$2.locale         = locale;
proto$2.localeData     = localeData;

// Deprecations
proto$2.toIsoString = deprecate('toIsoString() is deprecated. Please use toISOString() instead (notice the capitals)', toISOString$1);
proto$2.lang = lang;

// Side effect imports

// FORMATTING

addFormatToken('X', 0, 0, 'unix');
addFormatToken('x', 0, 0, 'valueOf');

// PARSING

addRegexToken('x', matchSigned);
addRegexToken('X', matchTimestamp);
addParseToken('X', function (input, array, config) {
    config._d = new Date(parseFloat(input, 10) * 1000);
});
addParseToken('x', function (input, array, config) {
    config._d = new Date(toInt(input));
});

// Side effect imports


hooks.version = '2.20.1';

setHookCallback(createLocal);

hooks.fn                    = proto;
hooks.min                   = min;
hooks.max                   = max;
hooks.now                   = now;
hooks.utc                   = createUTC;
hooks.unix                  = createUnix;
hooks.months                = listMonths;
hooks.isDate                = isDate;
hooks.locale                = getSetGlobalLocale;
hooks.invalid               = createInvalid;
hooks.duration              = createDuration;
hooks.isMoment              = isMoment;
hooks.weekdays              = listWeekdays;
hooks.parseZone             = createInZone;
hooks.localeData            = getLocale;
hooks.isDuration            = isDuration;
hooks.monthsShort           = listMonthsShort;
hooks.weekdaysMin           = listWeekdaysMin;
hooks.defineLocale          = defineLocale;
hooks.updateLocale          = updateLocale;
hooks.locales               = listLocales;
hooks.weekdaysShort         = listWeekdaysShort;
hooks.normalizeUnits        = normalizeUnits;
hooks.relativeTimeRounding  = getSetRelativeTimeRounding;
hooks.relativeTimeThreshold = getSetRelativeTimeThreshold;
hooks.calendarFormat        = getCalendarFormat;
hooks.prototype             = proto;

// currently HTML5 input type only supports 24-hour formats
hooks.HTML5_FMT = {
    DATETIME_LOCAL: 'YYYY-MM-DDTHH:mm',             // <input type="datetime-local" />
    DATETIME_LOCAL_SECONDS: 'YYYY-MM-DDTHH:mm:ss',  // <input type="datetime-local" step="1" />
    DATETIME_LOCAL_MS: 'YYYY-MM-DDTHH:mm:ss.SSS',   // <input type="datetime-local" step="0.001" />
    DATE: 'YYYY-MM-DD',                             // <input type="date" />
    TIME: 'HH:mm',                                  // <input type="time" />
    TIME_SECONDS: 'HH:mm:ss',                       // <input type="time" step="1" />
    TIME_MS: 'HH:mm:ss.SSS',                        // <input type="time" step="0.001" />
    WEEK: 'YYYY-[W]WW',                             // <input type="week" />
    MONTH: 'YYYY-MM'                                // <input type="month" />
};

return hooks;

})));
//  Copyright (c) 2002 M.Inamori,All rights reserved.
//  Coded 2/26/02
//
//	sprintf()

function sprintf() {
	var argv = sprintf.arguments;
	var argc = argv.length;
	if(argc == 0)
		return "";
	var result = "";
	var format = argv[0];
	var format_length = format.length;
	
	var flag, width, precision;
	flag = 0;
	
	var index = 1;
	var mode = 0;
	var tmpresult;
	var buff;
	for(var i = 0; i < format_length; i++) {
		var c = format.charAt(i);
		switch(mode) {
		case 0:		//normal
			if(c == '%') {
				tmpresult = c;
				mode = 1;
				buff = "";
			}
			else
				result += c;
			break;
		case 1:		//after '%'
			if(c == '%') {
				result += c;
				mode = 0;
				break;
			}
			if(index >= argc)
				argv[argc++] = "";
			width = 0;
			precision = -1;
			switch(c) {
			case '-':
				flag |= 1;
				mode = 1;
				break;
			case '+':
				flag |= 2;
				mode = 1;
				break;
			case '0':
				flag |= 4;
				mode = 2;
				break;
			case ' ':
				flag |= 8;
				mode = 1;
				break;
			case '#':
				flag |= 16;
				mode = 1;
				break;
			case '1': case '2': case '3': case '4': case '5':
			case '6': case '7': case '8': case '9':
				width = parseInt(c);
				mode = 2;
				break;
			case '-':
				flag = 1;
				mode = 2;
				break;
			case '.':
				width = "";
				precision = 0;
				mode = 3;
				break;
			case 'd':
				result += toInteger(argv[index], flag, width, precision);
				index++;
				mode = 0;
				break;
			case 'f':
				result += toFloatingPoint(argv[index], flag, width, 6);
				index++;
				mode = 0;
				break;
			case 'e':
				result += toExponential(argv[index], flag, width, 6, 'e');
				index++;
				mode = 0;
				break;
			case 'E':
				result += toExponential(argv[index], flag, width, 6, 'E');
				index++;
				mode = 0;
				break;
			case 's':
				result += argv[index];
				index++;
				mode = 0;
				break;
			default:
				result += buff + c;
				mode = 0;
				break;
			}
			break;
		case 2:		//while defining width
			switch(c) {
			case '.':
				precision = 0;
				mode = 3;
				break;
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
				width = width * 10 + parseInt(c);
				mode = 2;
				break;
			case 'd':
				result += toInteger(argv[index], flag, width, precision);
				index++;
				mode = 0;
				break;
			case 'f':
				result += toFloatingPoint(argv[index], flag, width, 6);
				index++;
				mode = 0;
				break;
			case 'e':
				result += toExponential(argv[index], flag, width, 6, 'e');
				index++;
				mode = 0;
				break;
			case 'E':
				result += toExponential(argv[index], flag, width, 6, 'E');
				index++;
				mode = 0;
				break;
			case 's':
				result += toFormatString(argv[index], width, precision);
				index++;
				mode = 0;
				break;
			default:
				result += buff + c;
				mode = 0;
				break;
			}
			break;
		case 3:		//while defining precision
			switch(c) {
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
				precision = precision * 10 + parseInt(c);
				break;
			case 'd':
				result += toInteger(argv[index], flag, width, precision);
				index++;
				mode = 0;
				break;
			case 'f':
				result += toFloatingPoint(argv[index], flag, width, precision);
				index++;
				mode = 0;
				break;
			case 'e':
				result += toExponential(argv[index], flag, width, precision, 'e');
				index++;
				mode = 0;
				break;
			case 'E':
				result += toExponential(argv[index], flag, width, precision, 'E');
				index++;
				mode = 0;
				break;
			case 's':
				result += toFormatString(argv[index], width, precision);
				index++;
				mode = 0;
				break;
			default:
				result += buff + c;
				mode = 0;
				break;
			}
			break;
		default:
			return "error";
		}
		
		if(mode)
			buff += c;
	}
	
	return result;
}

function toInteger(n, f, w, p) {
	if(typeof n != "number") {
		if(typeof n == "string") {
			n = parseFloat(n);
			if(isNaN(n))
				n = 0;
		}
		else
			n = 0;
	}
	
	var str = n.toString();
	
	//to integer if decimal
	if(-1 < n && n < 1)
		str = "0";
	else {
		if(n < 0)
			str = str.substring(1);
		var pos_e = str.indexOf('e');
		if(pos_e != -1) {		//指数
			var exp = parseInt(str.substring(pos_e + 2));
			var pos_dot = str.indexOf('.');
			if(pos_dot == -1) {
				str = str.substring(0, pos_e) + "000000000000000000000";
				exp -= 21;
			}
			else {
				str = str.substring(0, pos_dot)
							+ str.substring(pos_dot + 1, pos_e) + "00000";
				exp -= str.length - pos_dot;
			}
			for( ; exp; exp--)
				str += "0";
		}
		else {
			var pos_dot = str.indexOf('.');
			if(pos_dot != -1)
				str = str.substring(0, pos_dot);
		}
	}
	
	//精度
	var len = str.length;
	if(len < p) {
		var c = "0";
		for(var i = p - len; i; i--)
			str = c + str;
		len = p;
	}
	
	//フラグの処理
	return ProcFlag(str, f, w - len, n >= 0);
}

function toFloatingPoint(n, f, w, p) {
	if(typeof n != "number") {
		if(typeof n == "string") {
			n = parseFloat(n);
			if(isNaN(n))
				n = 0;
		}
		else
			n = 0;
	}
	
	var bpositive = (n >= 0);
	if(!bpositive)
		n = -n;
	
	str = toFloatingPoint2(n, f, p);
	
	//フラグの処理
	return ProcFlag(str, f, w - str.length, bpositive);
}

function toFloatingPoint2(n, f, p) {
	var str = n.toString();
	
	//to decimal if exponential
	var pos_e = str.indexOf('e');
	if(pos_e != -1) {
		var exp = parseInt(str.substring(pos_e + 1));
		if(exp > 0) {			//指数を整数に
			var pos_dot = str.indexOf('.');
			if(pos_dot == -1) {
				str = str.substring(0, pos_e) + "000000000000000000000";
				exp -= 21;
			}
			else {
				str = str.charAt(0) + str.substring(2, pos_e) + "00000";
				exp -= str.length - 1;
			}
			for( ; exp; exp--)
				str += "0";
		}
		else {					//指数を小数に
			var equive_p = exp + p;
			if(equive_p < -1)	//精度無し
				str = "0";
			else if(equive_p >= 0) {	//精度有り
				str = str.substring(0, pos_e);
				var pos_dot = str.indexOf(".");
				if(pos_dot != -1)
					str = str.charAt(0) + str.substring(2, pos_e);
				str = "000000" + str;
				for(exp += 7; exp; exp++)
					str = "0" + str;
				str = "0." + str;
			}
			else {				//微妙
				var tmp = parseFloat(str.substring(0, pos_e));
				if(tmp > 5) {	//切り上げ
					str = "0.00000";
					for(var i = exp + 7; i; i++)
						str += "0";
					str += "1";
				}
				else			//切捨て
					str = "0";
			}
		}
	}
	
	//精度で整形
	var len = str.length;
	var pos_dot = str.indexOf(".");
	if(pos_dot != -1) {
		var dec = len - pos_dot - 1;
		if(dec > p) {		//切る
			var tmp = parseFloat(str.charAt(pos_dot + p + 1)
									+ "." + str.substring(pos_dot + p + 2));
			if(tmp > 5) {	//切り上げ
				var i;
				if(n < 1) {
					i = 2;
					while(str.charAt(i) == "0")
						i++;
					tmp = (parseInt(str.substring(i, p + 2)) + 1).toString();
					if(tmp.length > p + 2 - i) {		//桁増
						if(i == 2)
							str = "1." + tmp.substring(1);
						else
							str = str.substring(0, i - 1) + tmp;
					}
					else
						str = str.substring(0, i) + tmp;
				}
				else {
					tmp = (parseInt(str.substring(0, pos_dot) + str.substring(
								pos_dot + 1, pos_dot + p + 1)) + 1).toString();
					if(tmp.length > pos_dot + p)				//桁増
						str = tmp.substring(0, pos_dot + 1)
									+ "." +  tmp.substring(pos_dot + 1);
					else
						str = tmp.substring(0, pos_dot)
									+ "." + tmp.substring(pos_dot);
				}
			}
			else {		//切捨て
				str = str.substring(0, p ? pos_dot + p + 1 : pos_dot);
			}
		}
		else if(dec < p) {	//"0"を充填
			for(var i = p - dec; i; i--)
				str += "0";
		}
	}
	else {
		if(p) {
			str += ".0";
			for(var i = p - 1; i; i--)
				str += "0";
		}
	}
	
	return str;
}

function toExponential(n, f, w, p, e) {
	if(typeof n != "number") {
		if(typeof n == "string") {
			n = parseFloat(n);
			if(isNaN(n))
				n = 0;
		}
		else
			n = 0;
	}
	
	var bpositive = n >= 0;
	if(!bpositive)
		n = -n;
	
	var str = n.toString();
	var pos_dot = str.indexOf(".");
	var pos_e = str.indexOf("e");
	var type = ((pos_e != -1) << 1) + (pos_dot != -1);
	var exp;
	
	//仮数部と指数部に分ける
	if(type == 0) {			//整数
		if(exp = str.length - 1)
			str = str.charAt(0) + "." + str.substring(pos_dot = 1);
	}
	else if(type == 1) {	//小数
		if(n > 10) {
			exp = pos_dot - 1;
			str = str.substring(0, 1) + "."
					+ str.substring(1, pos_dot) + str.substring(pos_dot + 1);
			pos_dot = 1;
		}
		else if(n > 1)
			exp = 0;
		else {
			for(var i = 2; ; i++) {
				if(str.charAt(i) != "0") {
					exp = 1 - i;
					str = str.charAt(i) + "." + str.substring(i + 1);
					break;
				}
			}
			pos_dot = 1;
		}
	}
	else {	//指数
		exp = parseInt(str.substring(pos_e + 1));
		str = str.substring(0, pos_e);
	}
	
	//仮数部の整形
	str = toFloatingPoint2(parseFloat(str), f, p);
	
	//指数部の整形
	if(exp >= 0)
		str += e + (exp < 10 ? "+0" : "+") + exp;
	else
		str += e + (exp > -10 ? "-0" + (-exp) : exp);
	
	//フラグの処理
	str = ProcFlag(str, f, w - str.length, bpositive);
	
	return str;
}

function toFormatString(s, w, p) {
	if(typeof s != "string")
		s = s.toString();
	
	var len = s.length;
	if(p >= 0) {
		if(p < len) {
			s = s.substring(0, p);
			len = p;
		}
	}
	if(len < w) {
		var c = " ";
		for(var i = w - len; i; i--)
			s = c + s;
	}
	
	return s;
}

function ProcFlag(str, f, extra, b) {
	var minus = f & 1;
	var plus = f & 2;
	var space = f & 8;
	if(space)			//with ' '
		extra--;
	extra -= !b + plus > 0;
	if((f & 4) > 0 && !minus) {	//with 0 and not -
		if(extra > 0) {
			var c = "0";
			for(var i = extra; i; i--)
				str = c + str;
		}
		if(!b)
			str = "-" + str;
		else if(plus)
			str = "+" + str;
	}
	else {					//without 0 or with -
		if(!b)
			str = "-" + str;
		else if(plus)
			str = "+" + str;
		var c = " ";
		if(extra > 0) {
			var c = " ";
			if(minus)
				for(var i = extra; i; i--)
					str += c;
			else
				for(var i = extra; i; i--)
					str = c + str;
		}
	}
	if(space)
		str = " " + str;
	
	return str;
}
;
/*! gridster.js - v0.7.0 - 2017-03-27 - * https://dsmorse.github.io/gridster.js/ - Copyright (c) 2017 ducksboard; Licensed MIT */
 !function(a,b){"use strict";"object"==typeof exports?module.exports=b(require("jquery")):"function"==typeof define&&define.amd?define("gridster-coords",["jquery"],b):a.GridsterCoords=b(a.$||a.jQuery)}(this,function(a){"use strict";function b(b){return b[0]&&a.isPlainObject(b[0])?this.data=b[0]:this.el=b,this.isCoords=!0,this.coords={},this.init(),this}var c=b.prototype;return c.init=function(){this.set(),this.original_coords=this.get()},c.set=function(a,b){var c=this.el;if(c&&!a&&(this.data=c.offset(),this.data.width=c[0].scrollWidth,this.data.height=c[0].scrollHeight),c&&a&&!b){var d=c.offset();this.data.top=d.top,this.data.left=d.left}var e=this.data;return void 0===e.left&&(e.left=e.x1),void 0===e.top&&(e.top=e.y1),this.coords.x1=e.left,this.coords.y1=e.top,this.coords.x2=e.left+e.width,this.coords.y2=e.top+e.height,this.coords.cx=e.left+e.width/2,this.coords.cy=e.top+e.height/2,this.coords.width=e.width,this.coords.height=e.height,this.coords.el=c||!1,this},c.update=function(b){if(!b&&!this.el)return this;if(b){var c=a.extend({},this.data,b);return this.data=c,this.set(!0,!0)}return this.set(!0),this},c.get=function(){return this.coords},c.destroy=function(){this.el.removeData("coords"),delete this.el},a.fn.coords=function(){if(this.data("coords"))return this.data("coords");var a=new b(this);return this.data("coords",a),a},b}),function(a,b){"use strict";"object"==typeof exports?module.exports=b(require("jquery")):"function"==typeof define&&define.amd?define("gridster-collision",["jquery","gridster-coords"],b):a.GridsterCollision=b(a.$||a.jQuery,a.GridsterCoords)}(this,function(a,b){"use strict";function c(b,c,e){this.options=a.extend(d,e),this.$element=b,this.last_colliders=[],this.last_colliders_coords=[],this.set_colliders(c),this.init()}var d={colliders_context:document.body,overlapping_region:"C"};c.defaults=d;var e=c.prototype;return e.init=function(){this.find_collisions()},e.overlaps=function(a,b){var c=!1,d=!1;return(b.x1>=a.x1&&b.x1<=a.x2||b.x2>=a.x1&&b.x2<=a.x2||a.x1>=b.x1&&a.x2<=b.x2)&&(c=!0),(b.y1>=a.y1&&b.y1<=a.y2||b.y2>=a.y1&&b.y2<=a.y2||a.y1>=b.y1&&a.y2<=b.y2)&&(d=!0),c&&d},e.detect_overlapping_region=function(a,b){var c="",d="";return a.y1>b.cy&&a.y1<b.y2&&(c="N"),a.y2>b.y1&&a.y2<b.cy&&(c="S"),a.x1>b.cx&&a.x1<b.x2&&(d="W"),a.x2>b.x1&&a.x2<b.cx&&(d="E"),c+d||"C"},e.calculate_overlapped_area_coords=function(b,c){var d=Math.max(b.x1,c.x1),e=Math.max(b.y1,c.y1);return a({left:d,top:e,width:Math.min(b.x2,c.x2)-d,height:Math.min(b.y2,c.y2)-e}).coords().get()},e.calculate_overlapped_area=function(a){return a.width*a.height},e.manage_colliders_start_stop=function(b,c,d){for(var e=this.last_colliders_coords,f=0,g=e.length;f<g;f++)a.inArray(e[f],b)===-1&&c.call(this,e[f]);for(var h=0,i=b.length;h<i;h++)a.inArray(b[h],e)===-1&&d.call(this,b[h])},e.find_collisions=function(b){for(var c=this,d=this.options.overlapping_region,e=[],f=[],g=this.colliders||this.$colliders,h=g.length,i=c.$element.coords().update(b||!1).get();h--;){var j=c.$colliders?a(g[h]):g[h],k=j.isCoords?j:j.coords(),l=k.get();if(c.overlaps(i,l)){var m=c.detect_overlapping_region(i,l);if(m===d||"all"===d){var n=c.calculate_overlapped_area_coords(i,l),o=c.calculate_overlapped_area(n);if(0!==o){var p={area:o,area_coords:n,region:m,coords:l,player_coords:i,el:j};c.options.on_overlap&&c.options.on_overlap.call(this,p),e.push(k),f.push(p)}}}}return(c.options.on_overlap_stop||c.options.on_overlap_start)&&this.manage_colliders_start_stop(e,c.options.on_overlap_start,c.options.on_overlap_stop),this.last_colliders_coords=e,f},e.get_closest_colliders=function(a){var b=this.find_collisions(a);return b.sort(function(a,b){return"C"===a.region&&"C"===b.region?a.coords.y1<b.coords.y1||a.coords.x1<b.coords.x1?-1:1:(a.area,b.area,1)}),b},e.set_colliders=function(b){"string"==typeof b||b instanceof a?this.$colliders=a(b,this.options.colliders_context).not(this.$element):this.colliders=a(b)},a.fn.collision=function(a,b){return new c(this,a,b)},c}),function(a,b){"use strict";a.delay=function(a,b){var c=Array.prototype.slice.call(arguments,2);return setTimeout(function(){return a.apply(null,c)},b)},a.debounce=function(a,b,c){var d;return function(){var e=this,f=arguments,g=function(){d=null,c||a.apply(e,f)};c&&!d&&a.apply(e,f),clearTimeout(d),d=setTimeout(g,b)}},a.throttle=function(a,b){var c,d,e,f,g,h,i=debounce(function(){g=f=!1},b);return function(){c=this,d=arguments;var j=function(){e=null,g&&a.apply(c,d),i()};return e||(e=setTimeout(j,b)),f?g=!0:h=a.apply(c,d),i(),f=!0,h}}}(window),function(a,b){"use strict";"object"==typeof exports?module.exports=b(require("jquery")):"function"==typeof define&&define.amd?define("gridster-draggable",["jquery"],b):a.GridsterDraggable=b(a.$||a.jQuery)}(this,function(a){"use strict";function b(b,d){this.options=a.extend({},c,d),this.$document=a(document),this.$container=a(b),this.$scroll_container=this.options.scroll_container===window?a(window):this.$container.closest(this.options.scroll_container),this.is_dragging=!1,this.player_min_left=0+this.options.offset_left,this.player_min_top=0+this.options.offset_top,this.id=i(),this.ns=".gridster-draggable-"+this.id,this.init()}var c={items:"li",distance:1,limit:{width:!0,height:!1},offset_left:0,autoscroll:!0,ignore_dragging:["INPUT","TEXTAREA","SELECT","BUTTON"],handle:null,container_width:0,move_element:!0,helper:!1,remove_helper:!0},d=a(window),e={x:"left",y:"top"},f=!!("ontouchstart"in window),g=function(a){return a.charAt(0).toUpperCase()+a.slice(1)},h=0,i=function(){return++h+""};b.defaults=c;var j=b.prototype;return j.init=function(){var b=this.$container.css("position");this.calculate_dimensions(),this.$container.css("position","static"===b?"relative":b),this.disabled=!1,this.events(),d.bind(this.nsEvent("resize"),throttle(a.proxy(this.calculate_dimensions,this),200))},j.nsEvent=function(a){return(a||"")+this.ns},j.events=function(){this.pointer_events={start:this.nsEvent("touchstart")+" "+this.nsEvent("mousedown"),move:this.nsEvent("touchmove")+" "+this.nsEvent("mousemove"),end:this.nsEvent("touchend")+" "+this.nsEvent("mouseup")},this.$container.on(this.nsEvent("selectstart"),a.proxy(this.on_select_start,this)),this.$container.on(this.pointer_events.start,this.options.items,a.proxy(this.drag_handler,this)),this.$document.on(this.pointer_events.end,a.proxy(function(a){this.is_dragging=!1,this.disabled||(this.$document.off(this.pointer_events.move),this.drag_start&&this.on_dragstop(a))},this))},j.get_actual_pos=function(a){return a.position()},j.get_mouse_pos=function(a){if(a.originalEvent&&a.originalEvent.touches){var b=a.originalEvent;a=b.touches.length?b.touches[0]:b.changedTouches[0]}return{left:a.clientX,top:a.clientY}},j.get_offset=function(a){a.preventDefault();var b=this.get_mouse_pos(a),c=Math.round(b.left-this.mouse_init_pos.left),d=Math.round(b.top-this.mouse_init_pos.top),e=Math.round(this.el_init_offset.left+c-this.baseX+this.$scroll_container.scrollLeft()-this.scroll_container_offset_x),f=Math.round(this.el_init_offset.top+d-this.baseY+this.$scroll_container.scrollTop()-this.scroll_container_offset_y);return this.options.limit.width&&(e>this.player_max_left?e=this.player_max_left:e<this.player_min_left&&(e=this.player_min_left)),this.options.limit.height&&(f>this.player_max_top?f=this.player_max_top:f<this.player_min_top&&(f=this.player_min_top)),{position:{left:e,top:f},pointer:{left:b.left,top:b.top,diff_left:c+(this.$scroll_container.scrollLeft()-this.scroll_container_offset_x),diff_top:d+(this.$scroll_container.scrollTop()-this.scroll_container_offset_y)}}},j.get_drag_data=function(a){var b=this.get_offset(a);return b.$player=this.$player,b.$helper=this.helper?this.$helper:this.$player,b},j.set_limits=function(a){return a||(a=this.$container.width()),this.player_max_left=a-this.player_width-this.options.offset_left,this.player_max_top=this.options.container_height-this.player_height-this.options.offset_top,this.options.container_width=a,this},j.scroll_in=function(a,b){var c,d=e[a],f=50,h=30,i="scroll"+g(d),j="x"===a,k=j?this.scroller_width:this.scroller_height;c=this.$scroll_container===window?j?this.$scroll_container.width():this.$scroll_container.height():j?this.$scroll_container[0].scrollWidth:this.$scroll_container[0].scrollHeight;var l,m=j?this.$player.width():this.$player.height(),n=this.$scroll_container[i](),o=n,p=o+k,q=p-f,r=o+f,s=o+b.pointer[d],t=c-k+m;return s>=q&&(l=n+h)<t&&(this.$scroll_container[i](l),this["scroll_offset_"+a]+=h),s<=r&&(l=n-h)>0&&(this.$scroll_container[i](l),this["scroll_offset_"+a]-=h),this},j.manage_scroll=function(a){this.scroll_in("x",a),this.scroll_in("y",a)},j.calculate_dimensions=function(){this.scroller_height=this.$scroll_container.height(),this.scroller_width=this.$scroll_container.width()},j.drag_handler=function(b){if(!this.disabled&&(1===b.which||f)&&!this.ignore_drag(b)){var c=this,d=!0;return this.$player=a(b.currentTarget),this.el_init_pos=this.get_actual_pos(this.$player),this.mouse_init_pos=this.get_mouse_pos(b),this.offsetY=this.mouse_init_pos.top-this.el_init_pos.top,this.$document.on(this.pointer_events.move,function(a){var b=c.get_mouse_pos(a),e=Math.abs(b.left-c.mouse_init_pos.left),f=Math.abs(b.top-c.mouse_init_pos.top);return(e>c.options.distance||f>c.options.distance)&&(d?(d=!1,c.on_dragstart.call(c,a),!1):(c.is_dragging===!0&&c.on_dragmove.call(c,a),!1))}),!!f&&void 0}},j.on_dragstart=function(a){if(a.preventDefault(),this.is_dragging)return this;this.drag_start=this.is_dragging=!0;var b=this.$container.offset();return this.baseX=Math.round(b.left),this.baseY=Math.round(b.top),"clone"===this.options.helper?(this.$helper=this.$player.clone().appendTo(this.$container).addClass("helper"),this.helper=!0):this.helper=!1,this.scroll_container_offset_y=this.$scroll_container.scrollTop(),this.scroll_container_offset_x=this.$scroll_container.scrollLeft(),this.el_init_offset=this.$player.offset(),this.player_width=this.$player.width(),this.player_height=this.$player.height(),this.set_limits(this.options.container_width),this.options.start&&this.options.start.call(this.$player,a,this.get_drag_data(a)),!1},j.on_dragmove=function(a){var b=this.get_drag_data(a);this.options.autoscroll&&this.manage_scroll(b),this.options.move_element&&(this.helper?this.$helper:this.$player).css({position:"absolute",left:b.position.left,top:b.position.top});var c=this.last_position||b.position;return b.prev_position=c,this.options.drag&&this.options.drag.call(this.$player,a,b),this.last_position=b.position,!1},j.on_dragstop=function(a){var b=this.get_drag_data(a);return this.drag_start=!1,this.options.stop&&this.options.stop.call(this.$player,a,b),this.helper&&this.options.remove_helper&&this.$helper.remove(),!1},j.on_select_start=function(a){if(!this.disabled&&!this.ignore_drag(a))return!1},j.enable=function(){this.disabled=!1},j.disable=function(){this.disabled=!0},j.destroy=function(){this.disable(),this.$container.off(this.ns),this.$document.off(this.ns),d.off(this.ns),a.removeData(this.$container,"drag")},j.ignore_drag=function(b){return this.options.handle?!a(b.target).is(this.options.handle):a.isFunction(this.options.ignore_dragging)?this.options.ignore_dragging(b):this.options.resize?!a(b.target).is(this.options.items):a(b.target).is(this.options.ignore_dragging.join(", "))},a.fn.gridDraggable=function(a){return new b(this,a)},a.fn.dragg=function(c){return this.each(function(){a.data(this,"drag")||a.data(this,"drag",new b(this,c))})},b}),function(a,b){"use strict";"object"==typeof exports?module.exports=b(require("jquery"),require("./jquery.draggable.js"),require("./jquery.collision.js"),require("./jquery.coords.js"),require("./utils.js")):"function"==typeof define&&define.amd?define(["jquery","gridster-draggable","gridster-collision"],b):a.Gridster=b(a.$||a.jQuery,a.GridsterDraggable,a.GridsterCollision)}(this,function(a,b,c){"use strict";function d(b,c){this.options=a.extend(!0,{},g,c),this.options.draggable=this.options.draggable||{},this.options.draggable=a.extend(!0,{},this.options.draggable,{scroll_container:this.options.scroll_container}),this.$el=a(b),this.$scroll_container=this.options.scroll_container===window?a(window):this.$el.closest(this.options.scroll_container),this.$wrapper=this.$el.parent(),this.$widgets=this.$el.children(this.options.widget_selector).addClass("gs-w"),this.$changed=a([]),this.w_queue={},this.is_responsive()?this.min_widget_width=this.get_responsive_col_width():this.min_widget_width=this.options.widget_base_dimensions[0],this.min_widget_height=this.options.widget_base_dimensions[1],this.is_resizing=!1,this.min_col_count=this.options.min_cols,this.prev_col_count=this.min_col_count,this.generated_stylesheets=[],this.$style_tags=a([]),typeof this.options.limit==typeof!0&&(console.log("limit: bool is deprecated, consider using limit: { width: boolean, height: boolean} instead"),this.options.limit={width:this.options.limit,height:this.options.limit}),this.options.auto_init&&this.init()}function e(a){for(var b=["col","row","size_x","size_y"],c={},d=0,e=b.length;d<e;d++){var f=b[d];if(!(f in a))throw new Error("Not exists property `"+f+"`");var g=a[f];if(!g||isNaN(g))throw new Error("Invalid value of `"+f+"` property");c[f]=+g}return c}var f=a(window),g={namespace:"",widget_selector:"li",static_class:"static",widget_margins:[10,10],widget_base_dimensions:[400,225],extra_rows:0,extra_cols:0,min_cols:1,max_cols:1/0,limit:{width:!0,height:!1},min_rows:1,max_rows:15,autogenerate_stylesheet:!0,avoid_overlapped_widgets:!0,auto_init:!0,center_widgets:!1,responsive_breakpoint:!1,scroll_container:window,shift_larger_widgets_down:!0,move_widgets_down_only:!1,shift_widgets_up:!0,show_element:function(a,b){b?a.fadeIn(b):a.fadeIn()},hide_element:function(a,b){b?a.fadeOut(b):a.fadeOut()},serialize_params:function(a,b){return{col:b.col,row:b.row,size_x:b.size_x,size_y:b.size_y}},collision:{wait_for_mouseup:!1},draggable:{items:".gs-w:not(.static)",distance:4,ignore_dragging:b.defaults.ignore_dragging.slice(0)},resize:{enabled:!1,axes:["both"],handle_append_to:"",handle_class:"gs-resize-handle",max_size:[1/0,1/0],min_size:[1,1]},ignore_self_occupied:!1};d.defaults=g,d.generated_stylesheets=[],d.sort_by_row_asc=function(b){return b=b.sort(function(b,c){return b.row||(b=a(b).coords().grid,c=a(c).coords().grid),b=e(b),c=e(c),b.row>c.row?1:-1})},d.sort_by_row_and_col_asc=function(a){return a=a.sort(function(a,b){return a=e(a),b=e(b),a.row>b.row||a.row===b.row&&a.col>b.col?1:-1})},d.sort_by_col_asc=function(a){return a=a.sort(function(a,b){return a=e(a),b=e(b),a.col>b.col?1:-1})},d.sort_by_row_desc=function(a){return a=a.sort(function(a,b){return a=e(a),b=e(b),a.row+a.size_y<b.row+b.size_y?1:-1})};var h=d.prototype;return h.init=function(){this.options.resize.enabled&&this.setup_resize(),this.generate_grid_and_stylesheet(),this.get_widgets_from_DOM(),this.set_dom_grid_height(),this.set_dom_grid_width(),this.$wrapper.addClass("ready"),this.draggable(),this.options.resize.enabled&&this.resizable(),this.options.center_widgets&&setTimeout(a.proxy(function(){this.center_widgets()},this),0),f.bind("resize.gridster",throttle(a.proxy(this.recalculate_faux_grid,this),200))},h.disable=function(){return this.$wrapper.find(".player-revert").removeClass("player-revert"),this.drag_api.disable(),this},h.enable=function(){return this.drag_api.enable(),this},h.disable_resize=function(){return this.$el.addClass("gs-resize-disabled"),this.resize_api.disable(),this},h.enable_resize=function(){return this.$el.removeClass("gs-resize-disabled"),this.resize_api.enable(),this},h.add_widget=function(b,c,d,e,f,g,h,i){var j;if(c||(c=1),d||(d=1),e||f)j={col:e,row:f,size_x:c,size_y:d},this.options.avoid_overlapped_widgets&&this.empty_cells(e,f,c,d);else if((j=this.next_position(c,d))===!1)return!1;var k=a(b).attr({"data-col":j.col,"data-row":j.row,"data-sizex":c,"data-sizey":d}).addClass("gs-w").appendTo(this.$el).hide();this.$widgets=this.$widgets.add(k),this.$changed=this.$changed.add(k),this.register_widget(k);var l=parseInt(j.row)+(parseInt(j.size_y)-1);return this.rows<l&&this.add_faux_rows(l-this.rows),g&&this.set_widget_max_size(k,g),h&&this.set_widget_min_size(k,h),this.set_dom_grid_width(),this.set_dom_grid_height(),this.drag_api.set_limits(this.cols*this.min_widget_width+(this.cols+1)*this.options.widget_margins[0]),this.options.center_widgets&&setTimeout(a.proxy(function(){this.center_widgets()},this),0),this.options.show_element.call(this,k,i),k},h.set_widget_min_size=function(a,b){if(a="number"==typeof a?this.$widgets.eq(a):a,!a.length)return this;var c=a.data("coords").grid;return c.min_size_x=b[0],c.min_size_y=b[1],this},h.set_widget_max_size=function(a,b){if(a="number"==typeof a?this.$widgets.eq(a):a,!a.length)return this;var c=a.data("coords").grid;return c.max_size_x=b[0],c.max_size_y=b[1],this},h.add_resize_handle=function(b){var c=this.options.resize.handle_append_to?a(this.options.resize.handle_append_to,b):b;return 0===c.children("span[class~='"+this.resize_handle_class+"']").length&&a(this.resize_handle_tpl).appendTo(c),this},h.resize_widget=function(a,b,c,d){var e=a.coords().grid;this.is_resizing=!0,b||(b=e.size_x),c||(c=e.size_y),this.is_valid_row(e.row,c)||this.add_faux_rows(Math.max(this.calculate_highest_row(e.row,c)-this.rows,0)),this.is_valid_col(e.col,c)||this.add_faux_cols(Math.max(this.calculate_highest_row(e.col,b)-this.cols,0));var f={col:e.col,row:e.row,size_x:b,size_y:c};return this.mutate_widget_in_gridmap(a,e,f),this.set_dom_grid_height(),this.set_dom_grid_width(),d&&d.call(this,f.size_x,f.size_y),this.is_resizing=!1,a},h.expand_widget=function(b,c,d,e,f){var g=b.coords().grid,h=Math.floor((a(window).width()-2*this.options.widget_margins[0])/this.min_widget_width);c=c||Math.min(h,this.cols),d||(d=g.size_y);var i=g.size_y;b.attr("pre_expand_col",g.col),b.attr("pre_expand_sizex",g.size_x),b.attr("pre_expand_sizey",g.size_y);var j=e||1;d>i&&this.add_faux_rows(Math.max(d-i,0));var k={col:j,row:g.row,size_x:c,size_y:d};return this.mutate_widget_in_gridmap(b,g,k),this.set_dom_grid_height(),this.set_dom_grid_width(),f&&f.call(this,k.size_x,k.size_y),b},h.collapse_widget=function(a,b){var c=a.coords().grid,d=parseInt(a.attr("pre_expand_sizex")),e=parseInt(a.attr("pre_expand_sizey")),f=parseInt(a.attr("pre_expand_col")),g={col:f,row:c.row,size_x:d,size_y:e};return this.mutate_widget_in_gridmap(a,c,g),this.set_dom_grid_height(),this.set_dom_grid_width(),b&&b.call(this,g.size_x,g.size_y),a},h.fit_to_content=function(a,b,c,d){var e=a.coords().grid,f=this.$wrapper.width(),g=this.$wrapper.height(),h=this.options.widget_base_dimensions[0]+2*this.options.widget_margins[0],i=this.options.widget_base_dimensions[1]+2*this.options.widget_margins[1],j=Math.ceil((f+2*this.options.widget_margins[0])/h),k=Math.ceil((g+2*this.options.widget_margins[1])/i),l={col:e.col,row:e.row,size_x:Math.min(b,j),size_y:Math.min(c,k)};return this.mutate_widget_in_gridmap(a,e,l),this.set_dom_grid_height(),this.set_dom_grid_width(),d&&d.call(this,l.size_x,l.size_y),a},h.center_widgets=debounce(function(){var b,c=this.$wrapper.width();b=this.is_responsive()?this.get_responsive_col_width():this.options.widget_base_dimensions[0]+2*this.options.widget_margins[0];var d=2*Math.floor(Math.max(Math.floor(c/b),this.min_col_count)/2);this.options.min_cols=d,this.options.max_cols=d,this.options.extra_cols=0,this.set_dom_grid_width(d),this.cols=d;var e=(d-this.prev_col_count)/2;return e<0?(this.get_min_col()>e*-1?this.shift_cols(e):this.resize_widget_dimensions(this.options),setTimeout(a.proxy(function(){this.resize_widget_dimensions(this.options)},this),0)):e>0?(this.resize_widget_dimensions(this.options),setTimeout(a.proxy(function(){this.shift_cols(e)},this),0)):(this.resize_widget_dimensions(this.options),setTimeout(a.proxy(function(){this.resize_widget_dimensions(this.options)},this),0)),this.prev_col_count=d,this},200),h.get_min_col=function(){return Math.min.apply(Math,this.$widgets.map(a.proxy(function(b,c){return this.get_cells_occupied(a(c).coords().grid).cols},this)).get())},h.shift_cols=function(b){var c=this.$widgets.map(a.proxy(function(b,c){var d=a(c);return this.dom_to_coords(d)},this));c=d.sort_by_row_and_col_asc(c),c.each(a.proxy(function(c,d){var e=a(d.el),f=e.coords().grid,g=parseInt(e.attr("data-col")),h={col:Math.max(Math.round(g+b),1),row:f.row,size_x:f.size_x,size_y:f.size_y};setTimeout(a.proxy(function(){this.mutate_widget_in_gridmap(e,f,h)},this),0)},this))},h.mutate_widget_in_gridmap=function(b,c,d){var e=c.size_y,f=this.get_cells_occupied(c),g=this.get_cells_occupied(d),h=[];a.each(f.cols,function(b,c){a.inArray(c,g.cols)===-1&&h.push(c)});var i=[];a.each(g.cols,function(b,c){a.inArray(c,f.cols)===-1&&i.push(c)});var j=[];a.each(f.rows,function(b,c){a.inArray(c,g.rows)===-1&&j.push(c)});var k=[];if(a.each(g.rows,function(b,c){a.inArray(c,f.rows)===-1&&k.push(c)}),this.remove_from_gridmap(c),i.length){var l=[d.col,d.row,d.size_x,Math.min(e,d.size_y),b];this.empty_cells.apply(this,l)}if(k.length){var m=[d.col,d.row,d.size_x,d.size_y,b];this.empty_cells.apply(this,m)}if(c.col=d.col,c.row=d.row,c.size_x=d.size_x,c.size_y=d.size_y,this.add_to_gridmap(d,b),b.removeClass("player-revert"),this.update_widget_dimensions(b,d),this.options.shift_widgets_up){if(h.length){var n=[h[0],d.row,h[h.length-1]-h[0]+1,Math.min(e,d.size_y),b];this.remove_empty_cells.apply(this,n)}if(j.length){var o=[d.col,d.row,d.size_x,d.size_y,b];this.remove_empty_cells.apply(this,o)}}return this.move_widget_up(b),this},h.empty_cells=function(b,c,d,e,f){return this.widgets_below({col:b,row:c-e,size_x:d,size_y:e}).not(f).each(a.proxy(function(b,d){var f=a(d),g=f.coords().grid;if(g.row<=c+e-1){var h=c+e-g.row;this.move_widget_down(f,h)}},this)),this.is_resizing||this.set_dom_grid_height(),this},h.remove_empty_cells=function(b,c,d,e,f){return this.widgets_below({col:b,row:c,size_x:d,size_y:e}).not(f).each(a.proxy(function(b,c){this.move_widget_up(a(c),e)},this)),this.set_dom_grid_height(),this},h.next_position=function(a,b){a||(a=1),b||(b=1);for(var c,e=this.gridmap,f=e.length,g=[],h=1;h<f;h++){c=e[h].length;for(var i=1;i<=c;i++){this.can_move_to({size_x:a,size_y:b},h,i)&&g.push({col:h,row:i,size_y:b,size_x:a})}}return!!g.length&&d.sort_by_row_and_col_asc(g)[0]},h.remove_by_grid=function(a,b){var c=this.is_widget(a,b);c&&this.remove_widget(c)},h.remove_widget=function(b,c,d){var e=b instanceof a?b:a(b);if(0===e.length)return this;var f=e.coords().grid;if(void 0===f)return this;a.isFunction(c)&&(d=c,c=!1),this.cells_occupied_by_placeholder={},this.$widgets=this.$widgets.not(e);var g=this.widgets_below(e);return this.remove_from_gridmap(f),this.options.hide_element.call(this,e,a.proxy(function(){e.remove(),c||g.each(a.proxy(function(b,c){this.move_widget_up(a(c),f.size_y)},this)),this.set_dom_grid_height(),d&&d.call(this,b)},this)),this},h.remove_all_widgets=function(b){return this.$widgets.each(a.proxy(function(a,c){this.remove_widget(c,!0,b)},this)),this},h.serialize=function(b){b||(b=this.$widgets);var c=[];return b.each(a.proxy(function(b,d){var e=a(d);void 0!==e.coords().grid&&c.push(this.options.serialize_params(e,e.coords().grid))},this)),c},h.serialize_changed=function(){return this.serialize(this.$changed)},h.dom_to_coords=function(a){return{col:parseInt(a.attr("data-col"),10),row:parseInt(a.attr("data-row"),10),size_x:parseInt(a.attr("data-sizex"),10)||1,size_y:parseInt(a.attr("data-sizey"),10)||1,max_size_x:parseInt(a.attr("data-max-sizex"),10)||!1,max_size_y:parseInt(a.attr("data-max-sizey"),10)||!1,min_size_x:parseInt(a.attr("data-min-sizex"),10)||!1,min_size_y:parseInt(a.attr("data-min-sizey"),10)||!1,el:a}},h.register_widget=function(b){var c=b instanceof a,d=c?this.dom_to_coords(b):b,e=!1;c||(b=d.el);var f=this.can_go_widget_up(d);return this.options.shift_widgets_up&&f&&(d.row=f,b.attr("data-row",f),this.$el.trigger("gridster:positionchanged",[d]),e=!0),this.options.avoid_overlapped_widgets&&!this.can_move_to({size_x:d.size_x,size_y:d.size_y},d.col,d.row)&&(a.extend(d,this.next_position(d.size_x,d.size_y)),b.attr({"data-col":d.col,"data-row":d.row,"data-sizex":d.size_x,"data-sizey":d.size_y}),e=!0),b.data("coords",b.coords()),b.data("coords").grid=d,this.add_to_gridmap(d,b),this.update_widget_dimensions(b,d),this.options.resize.enabled&&this.add_resize_handle(b),e},h.update_widget_position=function(a,b){return this.for_each_cell_occupied(a,function(a,c){if(!this.gridmap[a])return this;this.gridmap[a][c]=b}),this},h.update_widget_dimensions=function(a,b){var c=b.size_x*(this.is_responsive()?this.get_responsive_col_width():this.options.widget_base_dimensions[0])+(b.size_x-1)*this.options.widget_margins[0],d=b.size_y*this.options.widget_base_dimensions[1]+(b.size_y-1)*this.options.widget_margins[1];return a.data("coords").update({width:c,height:d}),a.attr({"data-col":b.col,"data-row":b.row,"data-sizex":b.size_x,"data-sizey":b.size_y}),this},h.update_widgets_dimensions=function(){return a.each(this.$widgets,a.proxy(function(b,c){var d=a(c).coords().grid;"object"==typeof d&&this.update_widget_dimensions(a(c),d)},this)),this},h.remove_from_gridmap=function(a){return this.update_widget_position(a,!1)},h.add_to_gridmap=function(a,b){this.update_widget_position(a,b||a.el)},h.draggable=function(){var b=this,c=a.extend(!0,{},this.options.draggable,{offset_left:this.options.widget_margins[0],offset_top:this.options.widget_margins[1],container_width:this.cols*this.min_widget_width+(this.cols+1)*this.options.widget_margins[0],container_height:this.rows*this.min_widget_height+(this.rows+1)*this.options.widget_margins[0],limit:{width:this.options.limit.width,height:this.options.limit.height},start:function(c,d){b.$widgets.filter(".player-revert").removeClass("player-revert"),b.$player=a(this),b.$helper=a(d.$helper),b.helper=!b.$helper.is(b.$player),b.on_start_drag.call(b,c,d),b.$el.trigger("gridster:dragstart")},stop:function(a,c){b.on_stop_drag.call(b,a,c),b.$el.trigger("gridster:dragstop")},drag:throttle(function(a,c){b.on_drag.call(b,a,c),b.$el.trigger("gridster:drag")},60)});this.drag_api=this.$el.dragg(c).data("drag")},h.resizable=function(){return this.resize_api=this.$el.gridDraggable({items:"."+this.options.resize.handle_class,offset_left:this.options.widget_margins[0],container_width:this.container_width,move_element:!1,resize:!0,limit:{width:this.options.max_cols!==1/0||this.limit.width,height:this.options.max_rows!==1/0||this.limit.height},scroll_container:this.options.scroll_container,start:a.proxy(this.on_start_resize,this),stop:a.proxy(function(b,c){delay(a.proxy(function(){this.on_stop_resize(b,c)},this),120)},this),drag:throttle(a.proxy(this.on_resize,this),60)}),this},h.setup_resize=function(){this.resize_handle_class=this.options.resize.handle_class;var b=this.options.resize.axes,c='<span class="'+this.resize_handle_class+" "+this.resize_handle_class+'-{type}" />';return this.resize_handle_tpl=a.map(b,function(a){return c.replace("{type}",a)}).join(""),a.isArray(this.options.draggable.ignore_dragging)&&this.options.draggable.ignore_dragging.push("."+this.resize_handle_class),this},h.on_start_drag=function(b,c){this.$helper.add(this.$player).add(this.$wrapper).addClass("dragging"),this.highest_col=this.get_highest_occupied_cell().col,this.$player.addClass("player"),this.player_grid_data=this.$player.coords().grid,this.placeholder_grid_data=a.extend({},this.player_grid_data),this.get_highest_occupied_cell().row+this.player_grid_data.size_y<=this.options.max_rows&&this.set_dom_grid_height(this.$el.height()+this.player_grid_data.size_y*this.min_widget_height),this.set_dom_grid_width(this.cols);var d=this.player_grid_data.size_x,e=this.cols-this.highest_col;this.options.max_cols===1/0&&e<=d&&this.add_faux_cols(Math.min(d-e,1));var f=this.faux_grid,g=this.$player.data("coords").coords;this.cells_occupied_by_player=this.get_cells_occupied(this.player_grid_data),this.cells_occupied_by_placeholder=this.get_cells_occupied(this.placeholder_grid_data),this.last_cols=[],this.last_rows=[],this.collision_api=this.$helper.collision(f,this.options.collision),this.$preview_holder=a("<"+this.$player.get(0).tagName+" />",{class:"preview-holder","data-row":this.$player.attr("data-row"),"data-col":this.$player.attr("data-col"),css:{width:g.width,height:g.height}}).appendTo(this.$el),this.options.draggable.start&&this.options.draggable.start.call(this,b,c)},h.on_drag=function(a,b){if(null===this.$player)return!1;var c=this.options.widget_margins,d=this.$preview_holder.attr("data-col"),e=this.$preview_holder.attr("data-row"),f={left:b.position.left+this.baseX-c[0]*d,top:b.position.top+this.baseY-c[1]*e};if(this.options.max_cols===1/0){this.placeholder_grid_data.col+this.placeholder_grid_data.size_x-1>=this.cols-1&&this.options.max_cols>=this.cols+1&&(this.add_faux_cols(1),this.set_dom_grid_width(this.cols+1),this.drag_api.set_limits(this.cols*this.min_widget_width+(this.cols+1)*this.options.widget_margins[0])),this.collision_api.set_colliders(this.faux_grid)}this.colliders_data=this.collision_api.get_closest_colliders(f),this.on_overlapped_column_change(this.on_start_overlapping_column,this.on_stop_overlapping_column),this.on_overlapped_row_change(this.on_start_overlapping_row,this.on_stop_overlapping_row),this.helper&&this.$player&&this.$player.css({left:b.position.left,top:b.position.top}),this.options.draggable.drag&&this.options.draggable.drag.call(this,a,b)},h.on_stop_drag=function(a,b){this.$helper.add(this.$player).add(this.$wrapper).removeClass("dragging");var c=this.options.widget_margins,d=this.$preview_holder.attr("data-col"),e=this.$preview_holder.attr("data-row");b.position.left=b.position.left+this.baseX-c[0]*d,b.position.top=b.position.top+this.baseY-c[1]*e,this.colliders_data=this.collision_api.get_closest_colliders(b.position),this.on_overlapped_column_change(this.on_start_overlapping_column,this.on_stop_overlapping_column),this.on_overlapped_row_change(this.on_start_overlapping_row,this.on_stop_overlapping_row),this.$changed=this.$changed.add(this.$player);var f=this.placeholder_grid_data.el.coords().grid;f.col===this.placeholder_grid_data.col&&f.row===this.placeholder_grid_data.row||(this.update_widget_position(f,!1),this.options.collision.wait_for_mouseup&&this.for_each_cell_occupied(this.placeholder_grid_data,function(a,b){if(this.is_widget(a,b)){var c=this.placeholder_grid_data.row+this.placeholder_grid_data.size_y,d=parseInt(this.gridmap[a][b][0].getAttribute("data-row")),e=c-d;!this.move_widget_down(this.is_widget(a,b),e)&&this.set_placeholder(this.placeholder_grid_data.el.coords().grid.col,this.placeholder_grid_data.el.coords().grid.row)}})),this.cells_occupied_by_player=this.get_cells_occupied(this.placeholder_grid_data);var g=this.placeholder_grid_data.col,h=this.placeholder_grid_data.row;this.set_cells_player_occupies(g,h),this.$player.coords().grid.row=h,this.$player.coords().grid.col=g,this.$player.addClass("player-revert").removeClass("player").attr({"data-col":g,"data-row":h}).css({left:"",top:""}),this.options.draggable.stop&&this.options.draggable.stop.call(this,a,b),this.$preview_holder.remove(),this.$player=null,this.$helper=null,this.placeholder_grid_data={},this.player_grid_data={},this.cells_occupied_by_placeholder={},this.cells_occupied_by_player={},this.w_queue={},this.set_dom_grid_height(),this.set_dom_grid_width(),this.options.max_cols===1/0&&this.drag_api.set_limits(this.cols*this.min_widget_width+(this.cols+1)*this.options.widget_margins[0])},h.on_start_resize=function(b,c){this.$resized_widget=c.$player.closest(".gs-w"),this.resize_coords=this.$resized_widget.coords(),this.resize_wgd=this.resize_coords.grid,this.resize_initial_width=this.resize_coords.coords.width,this.resize_initial_height=this.resize_coords.coords.height,this.resize_initial_sizex=this.resize_coords.grid.size_x,this.resize_initial_sizey=this.resize_coords.grid.size_y,this.resize_initial_col=this.resize_coords.grid.col,this.resize_last_sizex=this.resize_initial_sizex,this.resize_last_sizey=this.resize_initial_sizey,
this.resize_max_size_x=Math.min(this.resize_wgd.max_size_x||this.options.resize.max_size[0],this.options.max_cols-this.resize_initial_col+1),this.resize_max_size_y=this.resize_wgd.max_size_y||this.options.resize.max_size[1],this.resize_min_size_x=this.resize_wgd.min_size_x||this.options.resize.min_size[0]||1,this.resize_min_size_y=this.resize_wgd.min_size_y||this.options.resize.min_size[1]||1,this.resize_initial_last_col=this.get_highest_occupied_cell().col,this.set_dom_grid_width(this.cols),this.resize_dir={right:c.$player.is("."+this.resize_handle_class+"-x"),bottom:c.$player.is("."+this.resize_handle_class+"-y")},this.is_responsive()||this.$resized_widget.css({"min-width":this.options.widget_base_dimensions[0],"min-height":this.options.widget_base_dimensions[1]});var d=this.$resized_widget.get(0).tagName;this.$resize_preview_holder=a("<"+d+" />",{class:"preview-holder resize-preview-holder","data-row":this.$resized_widget.attr("data-row"),"data-col":this.$resized_widget.attr("data-col"),css:{width:this.resize_initial_width,height:this.resize_initial_height}}).appendTo(this.$el),this.$resized_widget.addClass("resizing"),this.options.resize.start&&this.options.resize.start.call(this,b,c,this.$resized_widget),this.$el.trigger("gridster:resizestart")},h.on_stop_resize=function(b,c){this.$resized_widget.removeClass("resizing").css({width:"",height:"","min-width":"","min-height":""}),delay(a.proxy(function(){this.$resize_preview_holder.remove().css({"min-width":"","min-height":""}),this.options.resize.stop&&this.options.resize.stop.call(this,b,c,this.$resized_widget),this.$el.trigger("gridster:resizestop")},this),300),this.set_dom_grid_width(),this.set_dom_grid_height(),this.options.max_cols===1/0&&this.drag_api.set_limits(this.cols*this.min_widget_width)},h.on_resize=function(a,b){var c,d=b.pointer.diff_left,e=b.pointer.diff_top,f=this.is_responsive()?this.get_responsive_col_width():this.options.widget_base_dimensions[0],g=this.options.widget_base_dimensions[1],h=this.options.widget_margins[0],i=this.options.widget_margins[1],j=this.resize_max_size_x,k=this.resize_min_size_x,l=this.resize_max_size_y,m=this.resize_min_size_y,n=this.options.max_cols===1/0,o=Math.ceil(d/(f+2*h)-.2),p=Math.ceil(e/(g+2*i)-.2),q=Math.max(1,this.resize_initial_sizex+o),r=Math.max(1,this.resize_initial_sizey+p),s=Math.floor(this.container_width/this.min_widget_width-this.resize_initial_col+1),t=s*this.min_widget_width+(s-1)*h;q=Math.max(Math.min(q,j),k),q=Math.min(s,q),c=j*f+(q-1)*h;var u=Math.min(c,t),v=k*f+(q-1)*h;r=Math.max(Math.min(r,l),m);var w=l*g+(r-1)*i,x=m*g+(r-1)*i;if(this.resize_dir.right?r=this.resize_initial_sizey:this.resize_dir.bottom&&(q=this.resize_initial_sizex),n){var y=this.resize_initial_col+q-1;n&&this.resize_initial_last_col<=y&&(this.set_dom_grid_width(Math.max(y+1,this.cols)),this.cols<y&&this.add_faux_cols(y-this.cols))}var z={};!this.resize_dir.bottom&&(z.width=Math.max(Math.min(this.resize_initial_width+d,u),v)),!this.resize_dir.right&&(z.height=Math.max(Math.min(this.resize_initial_height+e,w),x)),this.$resized_widget.css(z),q===this.resize_last_sizex&&r===this.resize_last_sizey||(this.resize_widget(this.$resized_widget,q,r,!1),this.set_dom_grid_width(this.cols),this.$resize_preview_holder.css({width:"",height:""}).attr({"data-row":this.$resized_widget.attr("data-row"),"data-sizex":q,"data-sizey":r})),this.options.resize.resize&&this.options.resize.resize.call(this,a,b,this.$resized_widget),this.$el.trigger("gridster:resize"),this.resize_last_sizex=q,this.resize_last_sizey=r},h.on_overlapped_column_change=function(b,c){if(!this.colliders_data.length)return this;var d,e=this.get_targeted_columns(this.colliders_data[0].el.data.col),f=this.last_cols.length,g=e.length;for(d=0;d<g;d++)a.inArray(e[d],this.last_cols)===-1&&(b||a.noop).call(this,e[d]);for(d=0;d<f;d++)a.inArray(this.last_cols[d],e)===-1&&(c||a.noop).call(this,this.last_cols[d]);return this.last_cols=e,this},h.on_overlapped_row_change=function(b,c){if(!this.colliders_data.length)return this;var d,e=this.get_targeted_rows(this.colliders_data[0].el.data.row),f=this.last_rows.length,g=e.length;for(d=0;d<g;d++)a.inArray(e[d],this.last_rows)===-1&&(b||a.noop).call(this,e[d]);for(d=0;d<f;d++)a.inArray(this.last_rows[d],e)===-1&&(c||a.noop).call(this,this.last_rows[d]);this.last_rows=e},h.set_player=function(b,c,d){var e=this,f=!1,g=d?{col:b}:e.colliders_data[0].el.data,h=g.col,i=g.row||c;this.player_grid_data={col:h,row:i,size_y:this.player_grid_data.size_y,size_x:this.player_grid_data.size_x},this.cells_occupied_by_player=this.get_cells_occupied(this.player_grid_data),this.cells_occupied_by_placeholder=this.get_cells_occupied(this.placeholder_grid_data);var j=this.get_widgets_overlapped(this.player_grid_data),k=this.player_grid_data.size_y,l=this.player_grid_data.size_x,m=this.cells_occupied_by_placeholder,n=this;if(j.each(a.proxy(function(b,c){var d=a(c),e=d.coords().grid,g=m.cols[0]+l-1,o=m.rows[0]+k-1;if(d.hasClass(n.options.static_class))return!0;if(n.options.collision.wait_for_mouseup&&n.drag_api.is_dragging)n.placeholder_grid_data.col=h,n.placeholder_grid_data.row=i,n.cells_occupied_by_placeholder=n.get_cells_occupied(n.placeholder_grid_data),n.$preview_holder.attr({"data-row":i,"data-col":h});else if(e.size_x<=l&&e.size_y<=k)if(n.is_swap_occupied(m.cols[0],e.row,e.size_x,e.size_y)||n.is_player_in(m.cols[0],e.row)||n.is_in_queue(m.cols[0],e.row,d))if(n.is_swap_occupied(g,e.row,e.size_x,e.size_y)||n.is_player_in(g,e.row)||n.is_in_queue(g,e.row,d))if(n.is_swap_occupied(e.col,m.rows[0],e.size_x,e.size_y)||n.is_player_in(e.col,m.rows[0])||n.is_in_queue(e.col,m.rows[0],d))if(n.is_swap_occupied(e.col,o,e.size_x,e.size_y)||n.is_player_in(e.col,o)||n.is_in_queue(e.col,o,d))if(n.is_swap_occupied(m.cols[0],m.rows[0],e.size_x,e.size_y)||n.is_player_in(m.cols[0],m.rows[0])||n.is_in_queue(m.cols[0],m.rows[0],d))for(var p=0;p<l;p++)for(var q=0;q<k;q++){var r=m.cols[0]+p,s=m.rows[0]+q;if(!n.is_swap_occupied(r,s,e.size_x,e.size_y)&&!n.is_player_in(r,s)&&!n.is_in_queue(r,s,d)){f=n.queue_widget(r,s,d),p=l;break}}else n.options.move_widgets_down_only?j.each(a.proxy(function(b,c){var d=a(c);n.can_go_down(d)&&d.coords().grid.row===n.player_grid_data.row&&!n.is_in_queue(g,e.row,d)&&(n.move_widget_down(d,n.player_grid_data.size_y),n.set_placeholder(h,i))})):f=n.queue_widget(m.cols[0],m.rows[0],d);else f=n.queue_widget(e.col,o,d);else f=n.queue_widget(e.col,m.rows[0],d);else f=n.queue_widget(g,e.row,d);else n.options.move_widgets_down_only?j.each(a.proxy(function(b,c){var d=a(c);n.can_go_down(d)&&d.coords().grid.row===n.player_grid_data.row&&!n.is_in_queue(d.coords().grid.col,e.row,d)&&(n.move_widget_down(d,n.player_grid_data.size_y),n.set_placeholder(h,i))})):f=n.queue_widget(m.cols[0],e.row,d);else n.options.shift_larger_widgets_down&&!f&&j.each(a.proxy(function(b,c){var d=a(c);n.can_go_down(d)&&d.coords().grid.row===n.player_grid_data.row&&(n.move_widget_down(d,n.player_grid_data.size_y),n.set_placeholder(h,i))}));n.clean_up_changed()})),f&&this.can_placeholder_be_set(h,i,l,k)){for(var o in this.w_queue){var p=parseInt(o.split("_")[0]),q=parseInt(o.split("_")[1]);"full"!==this.w_queue[o]&&this.new_move_widget_to(this.w_queue[o],p,q)}this.set_placeholder(h,i)}if(!j.length){if(this.options.shift_widgets_up){var r=this.can_go_player_up(this.player_grid_data);r!==!1&&(i=r)}this.can_placeholder_be_set(h,i,l,k)&&this.set_placeholder(h,i)}return this.w_queue={},{col:h,row:i}},h.is_swap_occupied=function(a,b,c,d){for(var e=!1,f=0;f<c;f++)for(var g=0;g<d;g++){var h=a+f,i=b+g,j=h+"_"+i;if(this.is_occupied(h,i))e=!0;else if(j in this.w_queue){if("full"===this.w_queue[j]){e=!0;continue}var k=this.w_queue[j],l=k.coords().grid;this.is_widget_under_player(l.col,l.row)||delete this.w_queue[j]}i>parseInt(this.options.max_rows)&&(e=!0),h>parseInt(this.options.max_cols)&&(e=!0),this.is_player_in(h,i)&&(e=!0)}return e},h.can_placeholder_be_set=function(a,b,c,d){for(var e=!0,f=0;f<c;f++)for(var g=0;g<d;g++){var h=a+f,i=b+g,j=this.is_widget(h,i);i>parseInt(this.options.max_rows)&&(e=!1),h>parseInt(this.options.max_cols)&&(e=!1),this.is_occupied(h,i)&&!this.is_widget_queued_and_can_move(j)&&(e=!1)}return e},h.queue_widget=function(a,b,c){var d=c,e=d.coords().grid,f=a+"_"+b;if(f in this.w_queue)return!1;this.w_queue[f]=d;for(var g=0;g<e.size_x;g++)for(var h=0;h<e.size_y;h++){var i=a+g,j=b+h,k=i+"_"+j;k!==f&&(this.w_queue[k]="full")}return!0},h.is_widget_queued_and_can_move=function(a){var b=!1;if(a===!1)return!1;for(var c in this.w_queue)if("full"!==this.w_queue[c]&&this.w_queue[c].attr("data-col")===a.attr("data-col")&&this.w_queue[c].attr("data-row")===a.attr("data-row")){b=!0;for(var d=this.w_queue[c],e=parseInt(c.split("_")[0]),f=parseInt(c.split("_")[1]),g=d.coords().grid,h=0;h<g.size_x;h++)for(var i=0;i<g.size_y;i++){var j=e+h,k=f+i;this.is_player_in(j,k)&&(b=!1)}}return b},h.is_in_queue=function(a,b,c){var d=!1,e=a+"_"+b;if(e in this.w_queue)if("full"===this.w_queue[e])d=!0;else{var f=this.w_queue[e],g=f.coords().grid;this.is_widget_under_player(g.col,g.row)?this.w_queue[e].attr("data-col")===c.attr("data-col")&&this.w_queue[e].attr("data-row")===c.attr("data-row")?(delete this.w_queue[e],d=!1):d=!0:(delete this.w_queue[e],d=!1)}return d},h.widgets_constraints=function(b){var c=a([]),e=[],f=[];return b.each(a.proxy(function(b,d){var g=a(d),h=g.coords().grid;this.can_go_widget_up(h)?(c=c.add(g),e.push(h)):f.push(h)},this)),b.not(c),{can_go_up:d.sort_by_row_asc(e),can_not_go_up:d.sort_by_row_desc(f)}},h.manage_movements=function(b,c,d){return a.each(b,a.proxy(function(a,b){var e=b,f=e.el,g=this.can_go_widget_up(e);if(g)this.move_widget_to(f,g),this.set_placeholder(c,g+e.size_y);else{if(!this.can_go_player_up(this.player_grid_data)){var h=d+this.player_grid_data.size_y-e.row;this.can_go_down(f)&&(console.log("In Move Down!"),this.move_widget_down(f,h),this.set_placeholder(c,d))}}},this)),this},h.is_player=function(a,b){if(b&&!this.gridmap[a])return!1;var c=b?this.gridmap[a][b]:a;return c&&(c.is(this.$player)||c.is(this.$helper))},h.is_player_in=function(b,c){var d=this.cells_occupied_by_player||{};return a.inArray(b,d.cols)>=0&&a.inArray(c,d.rows)>=0},h.is_placeholder_in=function(b,c){var d=this.cells_occupied_by_placeholder||{};return this.is_placeholder_in_col(b)&&a.inArray(c,d.rows)>=0},h.is_placeholder_in_col=function(b){var c=this.cells_occupied_by_placeholder||[];return a.inArray(b,c.cols)>=0},h.is_empty=function(a,b){return void 0===this.gridmap[a]||void 0!==this.gridmap[a][b]&&this.gridmap[a][b]===!1},h.is_valid_col=function(a,b){return this.options.max_cols===1/0||this.cols>=this.calculate_highest_col(a,b)},h.is_valid_row=function(a,b){return this.rows>=this.calculate_highest_row(a,b)},h.calculate_highest_col=function(a,b){return a+(b||1)-1},h.calculate_highest_row=function(a,b){return a+(b||1)-1},h.is_occupied=function(b,c){return!!this.gridmap[b]&&(!this.is_player(b,c)&&(!!this.gridmap[b][c]&&(!this.options.ignore_self_occupied||this.$player.data()!==a(this.gridmap[b][c]).data())))},h.is_widget=function(a,b){var c=this.gridmap[a];return!!c&&(!!(c=c[b])&&c)},h.is_static=function(a,b){var c=this.gridmap[a];return!!c&&!(!(c=c[b])||!c.hasClass(this.options.static_class))},h.is_widget_under_player=function(a,b){return!!this.is_widget(a,b)&&this.is_player_in(a,b)},h.get_widgets_under_player=function(b){b||(b=this.cells_occupied_by_player||{cols:[],rows:[]});var c=a([]);return a.each(b.cols,a.proxy(function(d,e){a.each(b.rows,a.proxy(function(a,b){this.is_widget(e,b)&&(c=c.add(this.gridmap[e][b]))},this))},this)),c},h.set_placeholder=function(b,c){var d=a.extend({},this.placeholder_grid_data),e=b+d.size_x-1;e>this.cols&&(b-=e-b);var f=this.placeholder_grid_data.row<c,g=this.placeholder_grid_data.col!==b;if(this.placeholder_grid_data.col=b,this.placeholder_grid_data.row=c,this.cells_occupied_by_placeholder=this.get_cells_occupied(this.placeholder_grid_data),this.$preview_holder.attr({"data-row":c,"data-col":b}),this.options.shift_player_up){if(f||g){this.widgets_below({col:d.col,row:d.row,size_y:d.size_y,size_x:d.size_x}).each(a.proxy(function(b,c){var d=a(c),e=d.coords().grid,f=this.can_go_widget_up(e);f&&this.move_widget_to(d,f)},this))}var h=this.get_widgets_under_player(this.cells_occupied_by_placeholder);h.length&&h.each(a.proxy(function(b,e){var f=a(e);this.move_widget_down(f,c+d.size_y-f.data("coords").grid.row)},this))}},h.can_go_player_up=function(a){var b=a.row+a.size_y-1,c=!0,d=[],e=1e4,f=this.get_widgets_under_player();return this.for_each_column_occupied(a,function(a){var g=this.gridmap[a],h=b+1;for(d[a]=[];--h>0&&(this.is_empty(a,h)||this.is_player(a,h)||this.is_widget(a,h)&&g[h].is(f));)d[a].push(h),e=h<e?h:e;if(0===d[a].length)return c=!1,!0;d[a].sort(function(a,b){return a-b})}),!!c&&this.get_valid_rows(a,d,e)},h.can_go_widget_up=function(a){var b=a.row+a.size_y-1,c=!0,d=[],e=1e4;return this.for_each_column_occupied(a,function(f){var g=this.gridmap[f];d[f]=[];for(var h=b+1;--h>0&&(!this.is_widget(f,h)||this.is_player_in(f,h)||g[h].is(a.el));)this.is_player(f,h)||this.is_placeholder_in(f,h)||this.is_player_in(f,h)||d[f].push(h),h<e&&(e=h);if(0===d[f].length)return c=!1,!0;d[f].sort(function(a,b){return a-b})}),!!c&&this.get_valid_rows(a,d,e)},h.get_valid_rows=function(b,c,d){for(var e=b.row,f=b.row+b.size_y-1,g=b.size_y,h=d-1,i=[];++h<=f;){var j=!0;if(a.each(c,function(b,c){a.isArray(c)&&a.inArray(h,c)===-1&&(j=!1)}),j===!0&&(i.push(h),i.length===g))break}var k=!1;return 1===g?i[0]!==e&&(k=i[0]||!1):i[0]!==e&&(k=this.get_consecutive_numbers_index(i,g)),k},h.get_consecutive_numbers_index=function(a,b){for(var c=a.length,d=[],e=!0,f=-1,g=0;g<c;g++){if(e||a[g]===f+1){if(d.push(g),d.length===b)break;e=!1}else d=[],e=!0;f=a[g]}return d.length>=b&&a[d[0]]},h.get_widgets_overlapped=function(){var b=a([]),c=[],d=this.cells_occupied_by_player.rows.slice(0);return d.reverse(),a.each(this.cells_occupied_by_player.cols,a.proxy(function(e,f){a.each(d,a.proxy(function(d,e){if(!this.gridmap[f])return!0;var g=this.gridmap[f][e];this.is_occupied(f,e)&&!this.is_player(g)&&a.inArray(g,c)===-1&&(b=b.add(g),c.push(g))},this))},this)),b},h.on_start_overlapping_column=function(a){this.set_player(a,void 0,!1)},h.on_start_overlapping_row=function(a){this.set_player(void 0,a,!1)},h.on_stop_overlapping_column=function(a){var b=this;this.options.shift_larger_widgets_down&&this.for_each_widget_below(a,this.cells_occupied_by_player.rows[0],function(a,c){b.move_widget_up(this,b.player_grid_data.size_y)})},h.on_stop_overlapping_row=function(a){var b=this,c=this.cells_occupied_by_player.cols;if(this.options.shift_larger_widgets_down)for(var d=0,e=c.length;d<e;d++)this.for_each_widget_below(c[d],a,function(a,c){b.move_widget_up(this,b.player_grid_data.size_y)})},h.new_move_widget_to=function(a,b,c){var d=a.coords().grid;return this.remove_from_gridmap(d),d.row=c,d.col=b,this.add_to_gridmap(d),a.attr("data-row",c),a.attr("data-col",b),this.update_widget_position(d,a),this.$changed=this.$changed.add(a),this},h.move_widget=function(a,b,c,d){var e=a.coords().grid,f={col:b,row:c,size_x:e.size_x,size_y:e.size_y};return this.mutate_widget_in_gridmap(a,e,f),this.set_dom_grid_height(),this.set_dom_grid_width(),d&&d.call(this,f.col,f.row),a},h.move_widget_to=function(b,c){var d=this,e=b.coords().grid,f=this.widgets_below(b);return this.can_move_to(e,e.col,c)!==!1&&(this.remove_from_gridmap(e),e.row=c,this.add_to_gridmap(e),b.attr("data-row",c),this.$changed=this.$changed.add(b),f.each(function(b,c){var e=a(c),f=e.coords().grid,g=d.can_go_widget_up(f);g&&g!==f.row&&d.move_widget_to(e,g)}),this)},h.move_widget_up=function(b,c){if(void 0===c)return!1;var d=b.coords().grid,e=d.row,f=[];if(c||(c=1),!this.can_go_up(b))return!1;this.for_each_column_occupied(d,function(d){if(a.inArray(b,f)===-1){var g=b.coords().grid,h=e-c;if(!(h=this.can_go_up_to_row(g,d,h)))return!0;this.remove_from_gridmap(g),g.row=h,this.add_to_gridmap(g),b.attr("data-row",g.row),this.$changed=this.$changed.add(b),f.push(b)}})},h.move_widget_down=function(b,c){var d,e,f,g;if(c<=0)return!1;if(d=b.coords().grid,(e=d.row)+(b.coords().grid.size_y-1)+c>this.options.max_rows)return!1;if(f=[],g=c,!b)return!1;if(this.failed=!1,a.inArray(b,f)===-1){var h=b.coords().grid,i=e+c;if(this.widgets_below(b).each(a.proxy(function(b,c){if(this.failed!==!0){var d=a(c),e=d.coords().grid,f=this.displacement_diff(e,h,g);f>0&&(this.failed=this.move_widget_down(d,f)===!1)}},this)),this.failed)return!1;this.remove_from_gridmap(h),h.row=i,this.update_widget_position(h,b),b.attr("data-row",h.row),this.$changed=this.$changed.add(b),f.push(b)}return!0},h.can_go_up_to_row=function(b,c,d){var e,f=!0,g=[],h=b.row;if(this.for_each_column_occupied(b,function(a){for(g[a]=[],e=h;e--&&this.is_empty(a,e)&&!this.is_placeholder_in(a,e);)g[a].push(e);if(!g[a].length)return f=!1,!0}),!f)return!1;for(e=d,e=1;e<h;e++){for(var i=!0,j=0,k=g.length;j<k;j++)g[j]&&a.inArray(e,g[j])===-1&&(i=!1);if(i===!0){f=e;break}}return f},h.displacement_diff=function(a,b,c){var d=a.row,e=[],f=b.row+b.size_y;return this.for_each_column_occupied(a,function(a){for(var b=0,c=f;c<d;c++)this.is_empty(a,c)&&(b+=1);e.push(b)}),c-=Math.max.apply(Math,e),c>0?c:0},h.widgets_below=function(b){var c=a([]),e=a.isPlainObject(b)?b:b.coords().grid;if(void 0===e)return c;var f=this,g=e.row+e.size_y-1;return this.for_each_column_occupied(e,function(b){f.for_each_widget_below(b,g,function(b,d){if(!f.is_player(this)&&a.inArray(this,c)===-1)return c=c.add(this),!0})}),d.sort_by_row_asc(c)},h.set_cells_player_occupies=function(a,b){return this.remove_from_gridmap(this.placeholder_grid_data),this.placeholder_grid_data.col=a,this.placeholder_grid_data.row=b,this.add_to_gridmap(this.placeholder_grid_data,this.$player),this},h.empty_cells_player_occupies=function(){return this.remove_from_gridmap(this.placeholder_grid_data),this},h.can_go_down=function(b){var c=!0,d=this;return b.hasClass(this.options.static_class)&&(c=!1),this.widgets_below(b).each(function(){a(this).hasClass(d.options.static_class)&&(c=!1)}),c},h.can_go_up=function(a){var b=a.coords().grid,c=b.row,d=c-1,e=!0;return 1!==c&&(this.for_each_column_occupied(b,function(a){if(this.is_occupied(a,d)||this.is_player(a,d)||this.is_placeholder_in(a,d)||this.is_player_in(a,d))return e=!1,!0}),e)},h.can_move_to=function(a,b,c){var d=a.el,e={size_y:a.size_y,size_x:a.size_x,col:b,row:c},f=!0;if(this.options.max_cols!==1/0){if(b+a.size_x-1>this.cols)return!1}return!(this.options.max_rows<c+a.size_y-1)&&(this.for_each_cell_occupied(e,function(b,c){var e=this.is_widget(b,c);!e||a.el&&!e.is(d)||(f=!1)}),f)},h.get_targeted_columns=function(a){for(var b=(a||this.player_grid_data.col)+(this.player_grid_data.size_x-1),c=[],d=a;d<=b;d++)c.push(d);return c},h.get_targeted_rows=function(a){for(var b=(a||this.player_grid_data.row)+(this.player_grid_data.size_y-1),c=[],d=a;d<=b;d++)c.push(d);return c},h.get_cells_occupied=function(b){var c,d={cols:[],rows:[]};for(arguments[1]instanceof a&&(b=arguments[1].coords().grid),c=0;c<b.size_x;c++){var e=b.col+c;d.cols.push(e)}for(c=0;c<b.size_y;c++){var f=b.row+c;d.rows.push(f)}return d},h.for_each_cell_occupied=function(a,b){return this.for_each_column_occupied(a,function(c){this.for_each_row_occupied(a,function(a){b.call(this,c,a)})}),this},h.for_each_column_occupied=function(a,b){for(var c=0;c<a.size_x;c++){var d=a.col+c;b.call(this,d,a)}},h.for_each_row_occupied=function(a,b){for(var c=0;c<a.size_y;c++){var d=a.row+c;b.call(this,d,a)}},h.clean_up_changed=function(){var b=this;b.$changed.each(function(){b.options.shift_larger_widgets_down&&b.move_widget_up(a(this))})},h._traversing_widgets=function(b,c,d,e,f){var g=this.gridmap;if(g[d]){var h,i,j=b+"/"+c;if(arguments[2]instanceof a){var k=arguments[2].coords().grid;d=k.col,e=k.row,f=arguments[3]}var l=[],m=e,n={"for_each/above":function(){for(;m--&&!(m>0&&this.is_widget(d,m)&&a.inArray(g[d][m],l)===-1&&(h=f.call(g[d][m],d,m),l.push(g[d][m]),h)););},"for_each/below":function(){for(m=e+1,i=g[d].length;m<i;m++)this.is_widget(d,m)&&a.inArray(g[d][m],l)===-1&&(h=f.call(g[d][m],d,m),l.push(g[d][m]))}};n[j]&&n[j].call(this)}},h.for_each_widget_above=function(a,b,c){return this._traversing_widgets("for_each","above",a,b,c),this},h.for_each_widget_below=function(a,b,c){return this._traversing_widgets("for_each","below",a,b,c),this},h.get_highest_occupied_cell=function(){for(var a,b=this.gridmap,c=b[1].length,d=[],e=[],f=b.length-1;f>=1;f--)for(a=c-1;a>=1;a--)if(this.is_widget(f,a)){d.push(a),e.push(f);break}return{col:Math.max.apply(Math,e),row:Math.max.apply(Math,d)}},h.get_widgets_in_range=function(b,c,d,e){var f,g,h,i,j=a([]);for(f=d;f>=b;f--)for(g=e;g>=c;g--)(h=this.is_widget(f,g))!==!1&&(i=h.data("coords").grid,i.col>=b&&i.col<=d&&i.row>=c&&i.row<=e&&(j=j.add(h)));return j},h.get_widgets_at_cell=function(a,b){return this.get_widgets_in_range(a,b,a,b)},h.get_widgets_from=function(b,c){var d=a();return b&&(d=d.add(this.$widgets.filter(function(){var c=parseInt(a(this).attr("data-col"));return c===b||c>b}))),c&&(d=d.add(this.$widgets.filter(function(){var b=parseInt(a(this).attr("data-row"));return b===c||b>c}))),d},h.set_dom_grid_height=function(a){if(void 0===a){var b=this.get_highest_occupied_cell().row;a=(b+1)*this.options.widget_margins[1]+b*this.min_widget_height}return this.container_height=a,this.$el.css("height",this.container_height),this},h.set_dom_grid_width=function(a){void 0===a&&(a=this.get_highest_occupied_cell().col);var b=this.options.max_cols===1/0?this.options.max_cols:this.cols;return a=Math.min(b,Math.max(a,this.options.min_cols)),this.container_width=(a+1)*this.options.widget_margins[0]+a*this.min_widget_width,this.is_responsive()?(this.$el.css({"min-width":"100%","max-width":"100%"}),this):(this.$el.css("width",this.container_width),this)},h.is_responsive=function(){return this.options.autogenerate_stylesheet&&"auto"===this.options.widget_base_dimensions[0]&&this.options.max_cols!==1/0},h.get_responsive_col_width=function(){var a=this.cols||this.options.max_cols;return(this.$el[0].clientWidth-3-(a+1)*this.options.widget_margins[0])/a},h.resize_responsive_layout=function(){return this.min_widget_width=this.get_responsive_col_width(),this.generate_stylesheet(),this.update_widgets_dimensions(),this.drag_api.set_limits(this.cols*this.min_widget_width+(this.cols+1)*this.options.widget_margins[0]),this},h.toggle_collapsed_grid=function(a,b){return a?(this.$widgets.css({"margin-top":b.widget_margins[0],"margin-bottom":b.widget_margins[0],"min-height":b.widget_base_dimensions[1]}),this.$el.addClass("collapsed"),this.resize_api&&this.disable_resize(),this.drag_api&&this.disable()):(this.$widgets.css({"margin-top":"auto","margin-bottom":"auto","min-height":"auto"}),this.$el.removeClass("collapsed"),this.resize_api&&this.enable_resize(),this.drag_api&&this.enable()),this},h.generate_stylesheet=function(b){var c,e="",f=this.is_responsive()&&this.options.responsive_breakpoint&&a(window).width()<this.options.responsive_breakpoint;b||(b={}),b.cols||(b.cols=this.cols),b.rows||(b.rows=this.rows),b.namespace||(b.namespace=this.options.namespace),b.widget_base_dimensions||(b.widget_base_dimensions=this.options.widget_base_dimensions),b.widget_margins||(b.widget_margins=this.options.widget_margins),this.is_responsive()&&(b.widget_base_dimensions=[this.get_responsive_col_width(),b.widget_base_dimensions[1]],this.toggle_collapsed_grid(f,b));var g=a.param(b);if(a.inArray(g,d.generated_stylesheets)>=0)return!1;for(this.generated_stylesheets.push(g),d.generated_stylesheets.push(g),c=1;c<=b.cols+1;c++)e+=b.namespace+' [data-col="'+c+'"] { left:'+(f?this.options.widget_margins[0]:c*b.widget_margins[0]+(c-1)*b.widget_base_dimensions[0])+"px; }\n";for(c=1;c<=b.rows+1;c++)e+=b.namespace+' [data-row="'+c+'"] { top:'+(c*b.widget_margins[1]+(c-1)*b.widget_base_dimensions[1])+"px; }\n";for(var h=1;h<=b.rows;h++)e+=b.namespace+' [data-sizey="'+h+'"] { height:'+(f?"auto":h*b.widget_base_dimensions[1]+(h-1)*b.widget_margins[1])+(f?"":"px")+"; }\n";for(var i=1;i<=b.cols;i++){var j=i*b.widget_base_dimensions[0]+(i-1)*b.widget_margins[0];e+=b.namespace+' [data-sizex="'+i+'"] { width:'+(f?this.$wrapper.width()-2*this.options.widget_margins[0]:j>this.$wrapper.width()?this.$wrapper.width():j)+"px; }\n"}return this.remove_style_tags(),this.add_style_tag(e)},h.add_style_tag=function(a){var b=document,c="gridster-stylesheet";if(""!==this.options.namespace&&(c=c+"-"+this.options.namespace),!document.getElementById(c)){var d=b.createElement("style");d.id=c,b.getElementsByTagName("head")[0].appendChild(d),d.setAttribute("type","text/css"),d.styleSheet?d.styleSheet.cssText=a:d.appendChild(document.createTextNode(a)),this.remove_style_tags(),this.$style_tags=this.$style_tags.add(d)}return this},h.remove_style_tags=function(){var b=d.generated_stylesheets,c=this.generated_stylesheets;this.$style_tags.remove(),d.generated_stylesheets=a.map(b,function(b){if(a.inArray(b,c)===-1)return b})},h.generate_faux_grid=function(a,b){this.faux_grid=[],this.gridmap=[];var c,d;for(c=b;c>0;c--)for(this.gridmap[c]=[],d=a;d>0;d--)this.add_faux_cell(d,c);return this},h.add_faux_cell=function(b,c){var d=a({left:this.baseX+(c-1)*this.min_widget_width,top:this.baseY+(b-1)*this.min_widget_height,width:this.min_widget_width,height:this.min_widget_height,col:c,row:b,original_col:c,original_row:b}).coords();return a.isArray(this.gridmap[c])||(this.gridmap[c]=[]),void 0===this.gridmap[c][b]&&(this.gridmap[c][b]=!1),this.faux_grid.push(d),this},h.add_faux_rows=function(a){a=window.parseInt(a,10);for(var b=this.rows,c=b+parseInt(a||1),d=c;d>b;d--)for(var e=this.cols;e>=1;e--)this.add_faux_cell(d,e);return this.rows=c,this.options.autogenerate_stylesheet&&this.generate_stylesheet(),this},h.add_faux_cols=function(a){a=window.parseInt(a,10);var b=this.cols,c=b+parseInt(a||1);c=Math.min(c,this.options.max_cols);for(var d=b+1;d<=c;d++)for(var e=this.rows;e>=1;e--)this.add_faux_cell(e,d);return this.cols=c,this.options.autogenerate_stylesheet&&this.generate_stylesheet(),this},h.recalculate_faux_grid=function(){var b=this.$wrapper.width();return this.baseX=(f.width()-b)/2,this.baseY=this.$wrapper.offset().top,"relative"===this.$wrapper.css("position")&&(this.baseX=this.baseY=0),a.each(this.faux_grid,a.proxy(function(a,b){this.faux_grid[a]=b.update({left:this.baseX+(b.data.col-1)*this.min_widget_width,top:this.baseY+(b.data.row-1)*this.min_widget_height})},this)),this.is_responsive()&&this.resize_responsive_layout(),this.options.center_widgets&&this.center_widgets(),this},h.resize_widget_dimensions=function(b){return b.widget_margins&&(this.options.widget_margins=b.widget_margins),b.widget_base_dimensions&&(this.options.widget_base_dimensions=b.widget_base_dimensions),this.min_widget_width=2*this.options.widget_margins[0]+this.options.widget_base_dimensions[0],this.min_widget_height=2*this.options.widget_margins[1]+this.options.widget_base_dimensions[1],this.$widgets.each(a.proxy(function(b,c){var d=a(c);this.resize_widget(d)},this)),this.generate_grid_and_stylesheet(),this.get_widgets_from_DOM(),this.set_dom_grid_height(),this.set_dom_grid_width(),this},h.get_widgets_from_DOM=function(){var b=this.$widgets.map(a.proxy(function(b,c){var d=a(c);return this.dom_to_coords(d)},this));return b=d.sort_by_row_and_col_asc(b),a(b).map(a.proxy(function(a,b){return this.register_widget(b)||null},this)).length&&this.$el.trigger("gridster:positionschanged"),this},h.get_num_widgets=function(){return this.$widgets.size()},h.set_num_columns=function(b){var c=this.options.max_cols,d=Math.floor(b/(this.min_widget_width+this.options.widget_margins[0]))+this.options.extra_cols,e=this.$widgets.map(function(){return a(this).attr("data-col")}).get();e.length||(e=[0]);var f=Math.max.apply(Math,e);this.cols=Math.max(f,d,this.options.min_cols),c!==1/0&&c>=f&&c<this.cols&&(this.cols=c),this.drag_api&&this.drag_api.set_limits(this.cols*this.min_widget_width+(this.cols+1)*this.options.widget_margins[0])},h.set_new_num_rows=function(b){var c=this.options.max_rows,d=this.$widgets.map(function(){return a(this).attr("data-row")}).get();d.length||(d=[0]);var e=Math.max.apply(Math,d);this.rows=Math.max(e,b,this.options.min_rows),c!==1/0&&(c<e||c<this.rows)&&(c=this.rows),this.min_rows=e,this.max_rows=c,this.options.max_rows=c;var f=this.rows*this.min_widget_height+(this.rows+1)*this.options.widget_margins[1];this.drag_api&&(this.drag_api.options.container_height=f),this.container_height=f,this.generate_faux_grid(this.rows,this.cols)},h.generate_grid_and_stylesheet=function(){var b=this.$wrapper.width();this.set_num_columns(b);var c=this.options.extra_rows;return this.$widgets.each(function(b,d){c+=+a(d).attr("data-sizey")}),this.rows=this.options.max_rows,this.baseX=(f.width()-b)/2,this.baseY=this.$wrapper.offset().top,this.options.autogenerate_stylesheet&&this.generate_stylesheet(),this.generate_faux_grid(this.rows,this.cols)},h.destroy=function(b){return this.$el.removeData("gridster"),a.each(this.$widgets,function(){a(this).removeData("coords")}),f.unbind(".gridster"),this.drag_api&&this.drag_api.destroy(),this.resize_api&&this.resize_api.destroy(),this.$widgets.each(function(b,c){a(c).coords().destroy()}),this.resize_api&&this.resize_api.destroy(),this.remove_style_tags(),b&&this.$el.remove(),this},a.fn.gridster=function(b){return this.each(function(){var c=a(this);c.data("gridster")||c.data("gridster",new d(this,b))})},d});
/**
 * Category Navi
 */

function Gws_Category_Navi(selector) {
  this.el = $(selector);
}

Gws_Category_Navi.prototype.setBaseUrl = function(url) {
  this.baseUrl = url;
};

Gws_Category_Navi.prototype.render = function(items) {
  if (items.length == 0) {
    this.el.hide();
    return;
  }
  var _this = this;
  var list = [];
  var line = list[0];
  var last_depth = -1;
  var path = location.href.replace(/https?:\/\/.*?\//, '/');
  var isCate = null;

  $.each(items, function(idx, item) {
    var depth = (item.name.match(/\//g) || []).length;
    var url = _this.baseUrl.replace('ID', item._id);

    if (depth == 0 || depth != last_depth) {
      list.push({ depth: depth, items: []});
      line = list[list.length - 1];
    }
    if (path.startsWith(url)) {
      isCate = item._id;
    }
    line.items.push('<a class="link-item" href="' + url + '">' + item.trailing_name + '</a>');
    last_depth = depth;
  });

  var html = [];
  $.each(list, function(idx, data) {
    html.push('<div class="depth depth-' + data.depth + '">');
    html.push(data.items.join('<span class="separator"></span>'));
    html.push('</div>');
  });
  this.el.find('.dropdown-menu').append(html.join(''));

  var toggle = this.el.find('.dropdown-toggle');
  if (isCate) {
    var icon = '<i class="material-icons md-18 md-dark">&#xE14C;</i>';
    toggle.after('<a class="ml-1" href="' + toggle.attr('href') + '">' + icon + '</a>');
  }
  toggle.on("click", function() {
    return false;
  });
};
// Tab
function Gws_Tab() {
}

Gws_Tab.renderTabs = function(selector) {
  var path = location.pathname + "/";
  $(selector).find('a').each(function() {
    var $menu = $(this);
    if (path.match(new RegExp('^' + $menu.attr('href') + '(\/|$)'))) {
      $menu.addClass("current")
    }
  });
};
this.Gws_Popup = (function () {
  function Gws_Popup() {
  }

  Gws_Popup.init = null;

  Gws_Popup.render = function (target, content) {
    var popup;
    if (!this.init) {
      this.init = true;
      $(window).resize(function () {
        return $('.gws-popup').remove();
      });
      $(document).on("click", function (ev) {
        if (!$(ev.target).closest('.gws-popup, .gws-popup-event').length) {
          return $('.gws-popup').remove();
        }
      });
    }
    $('.gws-popup').remove();
    popup = $("<div class='gws-popup'></div>").html($(content));
    $("body").append(popup);
    target.addClass('gws-popup-event');
    return this.renderPopup(target);

  };
  //$(window).resize(@render Popup)

  Gws_Popup.renderPopup = function (target) {
    var popup, pos_left, pos_top;
    popup = $('.gws-popup');
    if ($(window).width() < popup.outerWidth() * 1.5) {
      popup.css('max-width', $(window).width() / 2);
    } else {

    }
    //pop up.css(max'width',340 );
    pos_left = target.offset().left + (target.outerWidth() / 2) - (popup.outerWidth() / 2);
    pos_top = target.offset().top - popup.outerHeight() - 20;
    if (pos_left < 0) {
      pos_left = target.offset().left + target.outerWidth() / 2 - 20;
      popup.addClass('left');
    } else {
      popup.removeClass('left');
    }
    if (pos_left + popup.outerWidth() > $(window).width()) {
      pos_left = target.offset().left - popup.outerWidth() + target.outerWidth() / 2 + 20;
      popup.addClass('right');
    } else {
      popup.removeClass('right');
    }
    if (pos_top < 0) {
      pos_top = target.offset().top + target.outerHeight();
      popup.addClass('top');
    } else {
      popup.removeClass('top');
    }
    return popup.css({
      left: pos_left,
      top: pos_top
    }).animate({
      top: '+=10',
      opacity: 1
    }, 50);
  };

  return Gws_Popup;

})();
this.Gws_Member = (function () {
  function Gws_Member() {
  }

  Gws_Member.groups = null;

  Gws_Member.users = null;

  Gws_Member.render = function () {
    if ($('.js-copy-groups').length < 2) {
      $('.js-copy-groups').remove();
      $('.js-paste-groups').remove();
    }
    $('.js-copy-groups').on("click", function () {
      return Gws_Member.copyGroups($(this));
    });
    $('.js-paste-groups').on("click", function () {
      return Gws_Member.pasteGroups($(this));
    });
    if ($('.js-copy-users').length < 2) {
      $('.js-copy-users').remove();
      $('.js-paste-users').remove();
    }
    $('.js-copy-users').on("click", function () {
      return Gws_Member.copyUsers($(this));
    });
    return $('.js-paste-users').on("click", function () {
      return Gws_Member.pasteUsers($(this));
    });
  };

  Gws_Member.confirmReadableSetting = function () {
    return $('.save').on('click', function () {
//$(submit).trigger("click")
      if ($('.gws-addon-readable-setting tbody tr').length === 0) {
        return confirm("閲覧者が入力されていません。\\n全員に表示されますがよろしいですか？");
      }
    });
  };

  Gws_Member.copyGroups = function (el) {
    this.groups = el.closest('dl').find('tbody tr').clone(true);
    this.showLog(el, this.groups.length + "件のグループをコピーしました。");
    return false;
  };

  Gws_Member.pasteGroups = function (el) {
    var num;
    num = this.pasteItems(el, this.groups);
    this.showLog(el, num + "件のグループを追加しました。");
    return false;
  };

  Gws_Member.copyUsers = function (el) {
    this.users = el.closest('dl').find('tbody tr').clone(true);
    this.showLog(el, this.users.length + "件のユーザーをコピーしました。");
    return false;
  };

  Gws_Member.pasteUsers = function (el) {
    var num;
    num = this.pasteItems(el, this.users);
    this.showLog(el, num + "件のユーザーを追加しました。");
    return false;
  };

  Gws_Member.pasteItems = function (el, list) {
    var dl, name, num, tbody;
    if (!list || list.length === 0) {
      return 0;
    }
    dl = el.closest('dl');
    dl.find('table').show();
    tbody = dl.find('tbody');
    name = dl.find('.hidden-ids').attr('name');
    num = 0;
    list.each(function () {
      var tr;
      if (tbody.find('tr[data-id="' + $(this).data('id') + '"]').length === 0) {
        tr = $(this).clone(true);
        tr.find('input').attr('name', name);
        tbody.append(tr);
        return num += 1;
      }
    });
    return num;
  };

  Gws_Member.showLog = function (el, msg) {
    $(".gws-member-log").remove();
    return $("<span class='gws-member-log'>" + msg + "</span>").appendTo(el.parent()).hide().fadeIn(200);
  };

  return Gws_Member;

})();
this.Gws_Reminder = (function () {
  function Gws_Reminder() {
  }

  Gws_Reminder.renderList = function (opts) {
    var el;
    if (opts == null) {
      opts = {};
    }
    el = $(opts['el'] || document);
    el.find('.list-item').each(function () {
      return $(this).find('.links').prepend('<a class="restore" href="#" style="display: none;">元に戻す</a>');
    });
    el.find('.list-item.deleted').each(function () {
      $(this).find('.check, .meta, .delete, .updated, .more-btn').hide();
      $(this).find('.dropdown-menu').removeClass('active');
      $(this).find('.restore').show();
      return $(this).find('.notification').hide();
    });
    el.find('.list-item .delete').on("click", function () {
      var item;
      item = $(this).closest('.list-item');
      $.ajax({
        url: opts['url'],
        method: 'post',
        data: {
          _method: 'delete',
          id: item.data('id'),
          item_id: item.data('item_id'),
          item_model: item.data('model'),
          item_name: item.data('name'),
          date: item.data('date')
        },
        success: function (data) {
          item.toggleClass('gws-list-item--deleted').find('.check, .meta, .delete, .updated, .more-btn').hide();
          item.find('.dropdown-menu').removeClass('active');
          item.find('.restore').show();
          item.find('.notification').hide();
          return false;
        },
        error: function (data) {
          return alert('Error');
        }
      });
      return false;
    });
    return el.find('.list-item .restore').on("click", function () {
      var item;
      item = $(this).closest('.list-item');
      $.ajax({
        url: opts['restore_url'],
        method: 'post',
        data: {
          id: item.data('id'),
          item_id: item.data('item_id'),
          item_model: item.data('model'),
          item_name: item.data('name'),
          date: item.data('date')
        },
        success: function (data) {
          item.toggleClass('gws-list-item--deleted').find('.check, .meta, .delete, .more-btn').show();
          item.find('.restore').hide();
          if (item.find('.notification')[0]) {
            item.find('.notification')[0].selectedIndex = 0;
          }
          item.find('.notification').show();
          return false;
        },
        error: function (data) {
          return alert('Error');
        }
      });
      return false;
    });
  };

  return Gws_Reminder;

})();
function Gws_Bookmark() {
  this.bookmarkId = null;
  this.defaultName = null;
  this.url = null;
  this.model = null;
  this.el = $('.gws-bookmark');
  this.bookmarkIcon = "&#xE838;";
  this.unbookmarkIcon = "&#xE83A;";
  this.loading = false;
}

Gws_Bookmark.prototype.render = function(opts) {
  if (opts === null) {
    opts = {};
  }
  var _this = this;
  this.bookmarkId = opts['id'];
  this.defaultName = opts['default_name'];
  this.url = opts['url'];
  this.model = opts['model'];

  var icon;
  if (this.bookmarkId) {
    icon = this.bookmarkIcon;
  } else {
    icon = this.unbookmarkIcon;
  }
  var bookmarkName = opts['name'] || this.defaultName;

  var span = $('<span class="bookmark-icon"></span>').append($('<i class="material-icons"></i>').html(icon));
  var ul = $('<ul class="dropdown-menu"></ul>');
  var li = $('<li></li>');
  li.append($('<input name="bookmark[name]" id="bookmark_name" class="bookmark-name" type="text">').val(bookmarkName));
  li.append($('<input name="button" type="button" class="btn update" />').val(opts['save']));
  li.append($('<input name="button" type="button" class="btn delete" />').val(opts['delete']));
  ul.append($('<li><div class="bookmark-notice"></div></li>')).append(li);
  this.el.html(span).append(ul);

  this.el.on("click", function(e) {
    if (_this.loading) {
      return false;
    } else if ($(e.target).hasClass('update')) {
      _this.update();
    } else if ($(e.target).hasClass('delete')) {
      _this.delete();
    } else if (_this.bookmarkId) {
      _this.el.addClass('active');
      _this.el.find('.dropdown-menu').addClass('active');
    } else {
      _this.create();
    }
  });
};

Gws_Bookmark.prototype.create = function() {
  this.loading = true;
  var _this = this;
  var html = this.el.find('.dropdown-menu').html();
  this.el.find('.dropdown-menu').html(SS.loading);
  $.ajax({
    url: this.url,
    method: 'POST',
    data: {
      item: {
        name: this.defaultName,
        url: location.pathname + location.search,
        model: this.model
      }
    },
    success: function(data) {
      _this.el.find('.dropdown-menu').html(html);
      _this.el.addClass('active');
      _this.el.find('.dropdown-menu').addClass('active');
      _this.el.find('.material-icons').html(_this.bookmarkIcon);
      _this.el.find('.bookmark-notice').text(data['notice']);
      _this.el.find('.bookmark-name').val(_this.defaultName);
      _this.bookmarkId = data['bookmark_id'];
      _this.loading = false;
    },
    error: function() {
      alert('Error');
    }
  });
};

Gws_Bookmark.prototype.update = function() {
  this.loading = true;
  var _this = this;
  var newName = this.el.find('.bookmark-name').val() || this.defaultName;
  var uri = this.url + '/' + this.bookmarkId;
  var html = this.el.find('.dropdown-menu').html();
  this.el.find('.dropdown-menu').html(SS.loading);
  this.el.addClass('active');
  this.el.find('.dropdown-menu').addClass('active');
  $.ajax({
    url: uri,
    method: 'POST',
    data: {
      _method: 'patch',
      item: {
        name: newName,
        url: location.pathname + location.search,
        model: this.model
      }
    },
    success: function(data) {
      _this.el.find('.dropdown-menu').html(html);
      _this.el.removeClass('active');
      _this.el.find('.dropdown-menu').removeClass('active');
      _this.el.find('.material-icons').html(_this.bookmarkIcon);
      _this.el.find('.bookmark-notice').text(data['notice']);
      _this.el.find('.bookmark-name').val(newName);
      _this.bookmarkId = data['bookmark_id'];
      _this.loading = false;
    },
    error: function() {
      alert('Error');
    }
  });
};

Gws_Bookmark.prototype.delete = function() {
  var _this = this;
  if (!this.bookmarkId) {
    return false;
  }
  this.loading = true;
  var uri = this.url + '/' + this.bookmarkId;
  var html = this.el.find('.dropdown-menu').html();
  this.el.find('.dropdown-menu').html(SS.loading);
  this.el.addClass('active');
  this.el.find('.dropdown-menu').addClass('active');
  $.ajax({
    url: uri,
    method: 'POST',
    data: {
      _method: 'delete',
      item: {
        url: location.pathname + location.search
      }
    },
    success: function() {
      _this.el.find('.dropdown-menu').html(html);
      _this.el.removeClass('active');
      _this.el.find('.dropdown-menu').removeClass('active');
      _this.el.find('.material-icons').html(_this.unbookmarkIcon);
      _this.bookmarkId = null;
      _this.loading = false;
    },
    error: function() {
      alert('Error');
    }
  });
};
// Readable Setting UI
function Gws_ReadableSetting(selector) {
  this.el = $(selector);
}

Gws_ReadableSetting.prototype.render = function() {
  var _this = this;
  this.el.find('.buttons input').on("change", function() {
    var val = $(this).val();
    if (val == 'select') {
      _this.showSelectForm();
    } else {
      _this.hideSelectForm();
    }
  });

  var val = this.el.find('.buttons input:checked').val();
  if (val == 'select') {
    this.el.find('.gws-addon-readable-setting-select').show();
  } else {
    this.el.find('.gws-addon-readable-setting-select').hide();
  }
};

Gws_ReadableSetting.prototype.showSelectForm = function() {
  this.el.find('.gws-addon-readable-setting-select').slideDown("fast");
}

Gws_ReadableSetting.prototype.hideSelectForm = function() {
  this.el.find('.gws-addon-readable-setting-select').slideUp("fast");
}
;
function Gws_Contrast(opts) {
  this.opts = opts;
  this.$el = $('#user-contrast-menu');
  this.template = 'body * { color: :color !important; border-color: :color !important; background: :background !important; } ' +
                  'body *:after { background: :background !important; }';

  this.render();
}

Gws_Contrast.getContrastId = function(siteId) {
  return Cookies.get("gws-contrast-" + siteId);
};

Gws_Contrast.setContrastId = function(siteId, contrastId) {
  Cookies.set("gws-contrast-" + siteId, contrastId, { expires: 7, path: '/' });
};

Gws_Contrast.removeContrastId = function(siteId) {
  Cookies.remove("gws-contrast-" + siteId);
};

Gws_Contrast.prototype.render = function() {
  var _this = this;

  this.$el.data('load', function() {
    _this.loadContrasts();
  });

  this.$el.on('click', '.gws-contrast-item', function(ev) {
    var $this = $(this);
    var id = $this.data('id');
    if (id === 'default') {
      _this.removeContrast($this.data('text-color'), $this.data('color'));
      Gws_Contrast.removeContrastId(_this.opts.siteId);
    } else {
      _this.changeContrast($this.data('text-color'), $this.data('color'));
      Gws_Contrast.setContrastId(_this.opts.siteId, id);
    }
    SS.notice(_this.opts.notice.replace(':name', $this.text()));

    ev.stopPropagation();
  });
};

Gws_Contrast.prototype.loadContrasts = function() {
  if (this.$el.data('loadedAt')) {
    this.checkActiveContrast();
    return;
  }

  var _this = this;
  $.ajax({
    url: this.opts.url,
    type: 'GET',
    dataType: 'json',
    success: function(data) { _this.renderContrasts(data); },
    error: function(xhr, status, error) { _this.showMessage(this.opts.loadError); },
    complete: function(xhr, status) { _this.completeLoading(xhr); }
  });
};

Gws_Contrast.prototype.completeLoading = function(xhr) {
  this.$el.data('loadedAt', Date.now());
  this.$el.find('.gws-contrast-loading').closest('li').hide();
};

Gws_Contrast.prototype.showMessage = function(message) {
  this.$el.append($('<li/>').html('<div class="gws-contrast-error">' + message + '</div>'));
};

Gws_Contrast.prototype.renderContrasts = function(data) {
  if (data.length === 0) {
    this.showMessage(this.opts.noContrasts);
    return;
  }

  this.renderContrast('default', this.opts.defaultContrast);

  var _this = this;
  $.each(data, function() {
    _this.renderContrast(this._id['$oid'], this.name, this.color, this.text_color);
  });

  this.checkActiveContrast();
};

Gws_Contrast.prototype.renderContrast = function(id, name, color, textColor) {
  var dataAttrs = { id: id };
  if (color) {
    dataAttrs.color = color;
  }
  if (textColor) {
    dataAttrs.textColor = textColor;
  }

  var $input = $('<input/>', { type: 'radio', name: 'gws-contrast-item', value: id });
  var $label = $('<label/>', { class: 'gws-contrast-item', data: dataAttrs });
  $label.append($input);
  $label.append('<span class="gws-contrast-name">' + name + '</span>');

  this.$el.append($('<li/>').append($label));
};

Gws_Contrast.prototype.checkActiveContrast = function() {
  var contrastId = Gws_Contrast.getContrastId(this.opts.siteId);
  if (! contrastId) {
    $('input[name="gws-contrast-item"]').val(['default']);
    return;
  }

  $('input[name="gws-contrast-item"]').val([contrastId]);
};

Gws_Contrast.prototype.changeContrast = function(textColor, color) {
  if (! this.$style) {
    this.$style = $('<style/>', { type: 'text/css' });
    $('head').append(this.$style);
  }

  this.$style.html(this.template.replace(/:color/g, textColor).replace(/:background/g, color));
};

Gws_Contrast.prototype.removeContrast = function() {
  if (! this.$style) {
    return;
  }

  this.$style.html('');
};
this.Gws_Schedule_Plan = (function () {
  function Gws_Schedule_Plan() {
  }

  Gws_Schedule_Plan.diffOn = 3600000;

  Gws_Schedule_Plan.renderForm = function (opts) {
    if (opts == null) {
      opts = {};
    }
    $("input.date").datetimepicker({
      lang: "ja",
      timepicker: false,
      format: 'Y/m/d',
      closeOnDateSelect: true,
      scrollInput: false,
      maxDate: opts["maxDate"]
    });
    $("input.datetime").datetimepicker({
      lang: "ja",
      roundTime: 'ceil',
      step: 30,
      maxDate: opts["maxDate"]
    });
    this.relateDateForm();
    return this.relateDateTimeForm();
  };

  Gws_Schedule_Plan.renderAlldayForm = function () {
    this.changeDateForm();
    return $('#item_allday').on("change", function () {
      Gws_Schedule_Plan.changeDateValue();
      return Gws_Schedule_Plan.changeDateForm();
    });
  };
  // @example
  //   2015/09/29 00:00 => 2015/09/29
  //   2015/09/29 => 2015/09/29 00:00

  Gws_Schedule_Plan.changeDateValue = function () {
    var etime, stime;
    if ($('#item_allday').prop('checked')) {
      $('#item_start_on').val($('#item_start_at').val().replace(/ .*/, ''));
      return $('#item_end_on').val($('#item_end_at').val().replace(/ .*/, ''));
    } else {
      stime = $('#item_start_at').val().replace(/.* /, '');
      etime = $('#item_end_at').val().replace(/.* /, '');
      if (stime === '' && $('#item_start_on').val() !== '') {
        stime = '00:00';
      }
      if (etime === '' && $('#item_end_on').val() !== '') {
        etime = '00:00';
      }
      $('#item_start_at').val($('#item_start_on').val() + (" " + stime));
      return $('#item_end_at').val($('#item_end_on').val() + (" " + etime));
    }
  };

  Gws_Schedule_Plan.changeDateForm = function () {
    if ($('#item_allday').prop('checked')) {
      $('.dates-field').show();
      return $('.datetimes-field').hide();
    } else {
      $('.dates-field').hide();
      return $('.datetimes-field').show();
    }
  };

  Gws_Schedule_Plan.relateDateForm = function (start_sel, end_sel) {
    if (start_sel == null) {
      start_sel = '.date.start';
    }
    if (end_sel == null) {
      end_sel = '.date.end';
    }
    $(start_sel + ", " + end_sel).on("click", function () {
      return Gws_Schedule_Plan.diffOn = Gws_Schedule_Plan.diffDates($(start_sel).val(), $(end_sel).val());
    });
    $(start_sel).on("change", function () {
      var date, format, start;
      start = $(start_sel).val();
      if (!start) {
        return;
      }
      start = (new Date(start)).getTime();
      if (isNaN(start)) {
        return;
      }
      date = new Date();
      date.setTime(start + Gws_Schedule_Plan.diffOn);
      format = '%d/%02d/%02d';
      if ($(start_sel).hasClass('datetime')) {
        format = '%d/%02d/%02d %02d:%02d';
      }
      return $(end_sel).val(sprintf(format, date.getFullYear(), date.getMonth() + 1, date.getDate(), date.getHours(), date.getMinutes()));
    });
    if ($(end_sel).val() === "") {
      return $(start_sel).trigger("change");
    }
  };

  Gws_Schedule_Plan.relateDateTimeForm = function () {
    return this.relateDateForm('.datetime.start', '.datetime.end');
  };

  Gws_Schedule_Plan.diffDates = function (src, dst) {
    var diff;
    if (!src || !dst) {
      return 1000 * 60 * 60;
    }
    diff = (new Date(dst)).getTime() - (new Date(src)).getTime();
    if (diff < 0) {
      return 0;
    }
    return diff;
  };

  Gws_Schedule_Plan.transferEnd2Start = function () {
    if ($('#item_allday').prop('checked')) {
      return $('#item_start_on').val($('#item_end_on').val());
    } else {
      return $('#item_start_at').val($('#item_end_at').val());
    }
  };

  return Gws_Schedule_Plan;

})();
this.Gws_Schedule_Repeat_Plan = (function () {
  function Gws_Schedule_Repeat_Plan() {
  }

  Gws_Schedule_Repeat_Plan.renderForm = function () {
    this.changeRepeatForm();
    this.relateDateForm();
    return $('#item_repeat_type').on("change", function () {
      return Gws_Schedule_Repeat_Plan.changeRepeatForm();
    });
  };

  Gws_Schedule_Repeat_Plan.changeRepeatForm = function () {
    var repeat_type;
    repeat_type = $('#item_repeat_type').val();
    if (repeat_type === '') {
      return $('.gws-schedule-repeat').addClass("hide");
    } else {
      $('.gws-schedule-repeat').removeClass("hide");
      $(".repeat-daily, .repeat-weekly, .repeat-monthly").hide();
      return $(".repeat-" + repeat_type).show();
    }
  };

  Gws_Schedule_Repeat_Plan.relateDateForm = function () {
    return Gws_Schedule_Plan.relateDateForm('.date.repeat_start', '.date.repeat_end');
  };

  Gws_Schedule_Repeat_Plan.renderSubmitButtons = function () {
    var b1, b2, b3, buttons, form, sp;
    form = $("#main form");
    sp = '<span class="gws-schedule-btn-space"></span>';
    b1 = $('<input type="button" class="btn" value="' + "今回のみ" + '" />');
    b2 = $('<input type="button" class="btn" value="' + "以降すべて" + '" />');
    b3 = $('<input type="button" class="btn" value="' + "一連のスケジュールすべて" + '" />');
    b1.bind('click', function () {
      return form.append('<input type="hidden" name="item[edit_range]" value="one" />').submit();
    });
    b2.bind('click', function () {
      return form.append('<input type="hidden" name="item[edit_range]" value="later" />').submit();
    });
    b3.bind('click', function () {
      return form.append('<input type="hidden" name="item[edit_range]" value="all" />').submit();
    });
    buttons = $('<div class="gws-schedule-repeat-submit"></div>');
    buttons.append(b1).append(sp).append(b2).append(sp).append(b3);
    return $('.send .save, .send .delete').on("click", function () {
      if ($("#item_repeat_type").val() !== "") {
        $.colorbox({
          inline: true,
          href: buttons
        });
        return false;
      }
    });
  };

  return Gws_Schedule_Repeat_Plan;

})();

function Gws_Schedule_Integration() {
}

Gws_Schedule_Integration.paths = {};

Gws_Schedule_Integration.render = function() {
  var $el = $(".gws-schedule-box");
  if (! $el[0]) {
    return;
  }

  $el.find(".send-message").each(function() {
    $(this).on("click", function(ev) {
      var userId = $(this).closest("[data-user-id]").data("user-id");
      location.href = Gws_Schedule_Integration.paths.newMemoMessage + "?to%5B%5D=" + userId;
    });
  });

  $el.find(".send-email").each(function() {
    $(this).on("click", function(ev) {
      var email = $(this).closest("[data-email]").data("email");
      location.href = Gws_Schedule_Integration.paths.newWebmail + "?item%5Bto%5D=" + encodeURIComponent(email);
    });
  });

  $el.find(".copy-email-address").each(function() {
    $(this).on("click", function(ev) {
      $(this).closest("[data-email]").find(".clipboard-copy-button").trigger("click");

      $(".dropdown, .dropdown-menu").removeClass('active');

      ev.preventDefault();
      return false;
    });
  });
};
this.Gws_Schedule_Todo_Search = (function () {
  function Gws_Schedule_Todo_Search(el) {
    this.$el = $(el);
    this.templateHtml = this.$el.find("#schedule-todo-selected-member-template").html();

    this.render();
  }

  Gws_Schedule_Todo_Search.prototype.render = function() {
    var self = this;

    this.$el.find("select.schedule-todo-auto-submit").on("change", function() {
      self.scheduleToSubmit();
    });

    var $btn = this.$el.find(".schedule-todo-member-select-btn");
    if ($btn[0]) {
      var href = $btn.data("href");
      $btn.colorbox({ href: href, width: "90%", height: "90%" });

      $btn.data("on-select", function ($item) {
        var $x = $item.closest("[data-id]");
        if ($x.length === 0) {
          return;
        }

        self.selectUser($x.data());
      });

      this.$el.on("click", ".schedule-todo-selected-member .dismiss", function () {
        $(this).closest(".schedule-todo-selected-member").remove();
        self.scheduleToSubmit();
      });
    }
  };

  Gws_Schedule_Todo_Search.prototype.selectUser = function(userData) {
    var id = userData.id;
    var name = userData.longName;

    if (this.$el.find(".schedule-todo-selected-member[data-id=" + id + "]").length > 0) {
      return;
    }

    var html = this.templateHtml.replace(/#id/g, id).replace(/#name/g, name);
    this.$el.find(".schedule-todo-selected-members").append(html).removeClass("hide");
    this.scheduleToSubmit();
  };

  Gws_Schedule_Todo_Search.prototype.scheduleToSubmit = function() {
    if (this.timerId) {
      return;
    }

    var self = this;
    this.timerId = setTimeout(function() { self.$el.submit(); }, 0);
  };

  return Gws_Schedule_Todo_Search;

})();
this.Gws_Schedule_Todo_Index = (function () {
  function Gws_Schedule_Todo_Index(el) {
    this.$el = $(el);
    this.render();
  }

  var showEl = function($el) {
    $el.removeClass("hide");
  };

  var hideEl = function($el) {
    $el.addClass("hide");
  };

  var isExpanded = function($listItemHeader) {
    var status = $listItemHeader.find(".list-item-switch").html();
    return status === "expand_less";
  };

  Gws_Schedule_Todo_Index.prototype.render = function() {
    var self = this;

    this.$el.find(".gws-schedule-todo-list-item-header").on("click", function() {
      self.toggleListItems($(this));
    });
  };

  Gws_Schedule_Todo_Index.prototype.toggleListItems = function($listItemHeader) {
    if (isExpanded($listItemHeader)) {
      this.collapseListItems($listItemHeader);
    } else {
      this.expandListItems($listItemHeader);
    }
  };

  Gws_Schedule_Todo_Index.prototype.collapseListItems = function($listItemHeader) {
    $listItemHeader.find(".list-item-switch").html("expand_more");
    this.eachListItem($listItemHeader, function() {
      hideEl($(this));
    });
  };

  Gws_Schedule_Todo_Index.prototype.expandListItems = function($listItemHeader) {
    $listItemHeader.find(".list-item-switch").html("expand_less");

    var self = this;
    this.eachListItem($listItemHeader, function() {
      var $this = $(this);
      if (self.examineToShow($this)) {
        showEl($(this));
      }
    });
  };

  Gws_Schedule_Todo_Index.prototype.examineToShow = function($listItem) {
    if ($listItem.hasClass("gws-schedule-todo-list-item-header")) {
      var parentGroup = $listItem.data("parent");
      if (parentGroup) {
        return this.examineToShow(this.$el.find("#" + parentGroup));
      }

      return true;
    }

    var listItemGroup = $listItem.data("group");
    var $listItemHeader = this.$el.find("#" + listItemGroup);
    if (!isExpanded($listItemHeader)) {
      return false;
    }

    var parentGroup = $listItemHeader.data("parent");
    if (parentGroup) {
      return this.examineToShow(this.$el.find("#" + parentGroup));
    }

    return true;
  };

  Gws_Schedule_Todo_Index.prototype.eachListItem = function($listItemHeader, callback) {
    var targetGroup = $listItemHeader.data("group");
    var targetDepth = $listItemHeader.data("depth");

    $.each($listItemHeader.nextAll(".list-item"), function() {
      var $this = $(this);
      var group = $this.data("group");
      var depth = $this.data("depth");
      if (group !== targetGroup && depth <= targetDepth) {
        return false;
      }

      callback.apply(this);
    });
  };

  return Gws_Schedule_Todo_Index;

})();
function Gws_Schedule_Csv(el) {
  this.$el = $(el);
  this.$importMode = this.$el.find('#import_mode');
  this.$importLog = this.$el.find('.import-log');
}

Gws_Schedule_Csv.render = function (el) {
  var instance = new Gws_Schedule_Csv(el);
  instance.render();
  return instance;
};

Gws_Schedule_Csv.prototype.render = function () {
  var self = this;
  this.$el.find('.import-confirm').on("click", function(){
    self.$importMode.val('confirm');
  });
  this.$el.find('.import-save').on("click", function(){
    self.$importMode.val('save');
  });
  this.$el.find('#import_form').ajaxForm({
    beforeSubmit: function() {
      self.$importLog.html('<span class="import-loading">アップロードしています。</span>');
      SS_AddonTabs.show('#import-result');
    },
    success: function(data, status) {
      self.renderResult(data);
    },
    error: function(xhr, status, error) {
      self.renderError(data);
    }
  });
//  this.$el.find('.download-csv-template').on("click", function() {
//    setTimeout(function() { self.showCsvDescription(); }, 0);
//    return true;
//  });
  this.$el.find('.show-csv-description').on("click", function() {
    self.showCsvDescription();
  });
}

Gws_Schedule_Csv.prototype.renderResult = function(data) {
  var log = this.$importLog;
  log.html('')

  if (data.messages) {
    log.append('<div class="mb-1">' + data.messages.join('<br />') + '</div>');
  }
  if (data.items) {
    var count = { exist: 0, entry: 0, saved: 0, error: 0 };
    var html = '<table class="index mt-1"><thead><tr>' +
      '<th style="width: 150px">開始日時</th>' +
      '<th style="width: 150px">終了日時</th>' +
      '<th style="width: 30%">タイトル</th>' +
      '<th>結果</th>' +
      '</tr></thead><tbody>';

    $.each(data.items, function(i, item){
      if (item.result == 'exist') count.exist += 1;
      if (item.result == 'entry') count.entry += 1;
      if (item.result == 'saved') count.saved += 1;
      if (item.result == 'error') count.error += 1;

      html += '<tr class="import-' + item.result + '">' +
        '<td>' + SS.formatTime(item.start_at) + '</td>' +
        '<td>' + SS.formatTime(item.end_at) + '</td>' +
        '<td>' + item.name + '</td>' +
        '<td>' + item.messages.join('<br />') + '</td>' +
        '</tr>'
    });
    html += '</tbody></table>';

    var tabs = '<div class="mb-1">';
    if (count.exist) tabs += '<span class="ml-2 import-exist">登録済み(' + count.exist + ')</span>';
    if (count.entry) tabs += '<span class="ml-2 import-entry">登録可能(' + count.entry + ')</span>';
    if (count.saved) tabs += '<span class="ml-2 import-saved">登録完了(' + count.saved + ')</span>';
    if (count.error) tabs += '<span class="ml-2 import-error">エラー(' + count.error + ')</span>';
    tabs += '</div>'

    log.append(tabs + html);
  }
}

Gws_Schedule_Csv.prototype.renderError = function(xhr, status, error) {
  try {
    var errors = xhr.responseJSON;
    var msg = errors.join("\n");
    this.$importLog.html(msg);
  } catch (ex) {
    this.$importLog.html("Error: " + error);
  }
};

Gws_Schedule_Csv.prototype.showCsvDescription = function() {
  var href = this.$el.find('.show-csv-description').attr("href");
  $.colorbox({
    inline: true, href: href, width: "90%", height: "90%", fixed: true, open: true
  });
};
this.Gws_Memo_Message = (function () {
  function Gws_Memo_Message() {
  }

  Gws_Memo_Message.render = function () {
    $(".list-head .search").on("click", function () {
      $(".gws-memo-search").animate({ height: "toggle" }, "fast");
    });

    $(".gws-memo-search .reset").on("click", function () {
      $(".gws-memo-search input[type=text]").val("");
      $(".gws-memo-search input[type=checkbox]").val("");
      $(".gws-memo-search .search").trigger("click");
    });

    $('.cc-bcc-label').on("click", function () {
      $('.gws-addon-memo-member .cc-bcc').animate({ height: 'toggle' }, 'fast');
      return false;
    });

    $('.add-template').on("change", function () {
      if ($(this).val() === "") {
        return;
      }
      if ($('#item_format').val() === "html") {
        CKEDITOR.instances['item_html'].insertText($(this).val());
      } else {
        Webmail_Mail_Form.insertText($("#item_text"), $(this).val());
      }
      $(this).val("");
    });

    $(".send-mdn,.ignore-mdn").on("click", function () {
      if ($(this).hasClass('disabled')) {
        return false;
      }

      $.ajax({
        url: $(this).attr("href"),
        method: 'POST',
        dataType: 'json',
        data: {
          _method: 'put',
          authenticity_token: $('meta[name="csrf-token"]').attr('content')
        },
        beforeSend: function () {
          return $(".send-mdn,.ignore-mdn").addClass('disabled');
        },
        success: function (data) {
          SS.notice(data.notice);
          return $(".request-mdn-notice").remove();
        }
      });
    });

    $(".icon-star a").on("click", function () {
      var $wrap = $(this).parent();
      var url;
      if ($wrap.hasClass('on')) {
        url = $(this).attr('href') + '/unset_star';
      } else {
        url = $(this).attr('href') + '/set_star';
      }
      $.ajax({
        url: url,
        method: 'POST',
        dataType: 'json',
        data: {
          _method: 'put'
        },
        success: function (data) {
          if (data.action === 'set_star') {
            $wrap.removeClass('off').addClass('on');
          } else {
            $wrap.removeClass('on').addClass('off');
          }
          if (data.notice) {
            SS.notice(data.notice);
          }
        }
      });
      return false;
    });
  };

  Gws_Memo_Message.buildForm = function (action, confirm) {
    var checked = $(".list-item input:checkbox:checked").map(function () {
      return $(this).val();
    });
    if (checked.length === 0) {
      return false;
    }
    var token = $('meta[name="csrf-token"]').attr("content");
    var form = $("<form/>", { action: action, method: "post", data: { confirm: confirm } });
    form.append($("<input/>", { name: "authenticity_token", value: token, type: "hidden" }));
    var i, len;
    for (i = 0, len = checked.length; i < len; i++) {
      var id = checked[i];
      form.append($("<input/>", { name: "ids[]", value: id, type: "hidden" }));
    }
    return form;
  };

  return Gws_Memo_Message;

})();
function Gws_Memo_Folder() {
}

Gws_Memo_Folder.render = function () {
  return $("#addon-gws-agents-addons-group_permission").hide();
};
function Gws_Memo_Filter() {
}

Gws_Memo_Filter.render = function () {
  return $("#addon-gws-agents-addons-group_permission").hide();
};
this.Gws_Monitor_Topic = (function () {
  function Gws_Monitor_Topic() {
  }

  Gws_Monitor_Topic.render = function () {
    $(".public").on("click", function () {
      var $this, action, confirm, form, token;
      token = $('meta[name="csrf-token"]').attr('content');
      $this = $(this);
      action = $this.data('ss-action');
      confirm = $this.data('ss-confirm');
      form = $("<form/>", {
        action: action,
        method: "post",
        data: {
          confirm: confirm
        }
      });
      form.append($("<input/>", {
        name: "authenticity_token",
        value: token,
        type: "hidden"
      }));
      return form.appendTo(document.body).submit();
    });
    $(".preparation").on("click", function () {
      var $this, action, confirm, form, token;
      token = $('meta[name="csrf-token"]').attr('content');
      $this = $(this);
      action = $this.data('ss-action');
      confirm = $this.data('ss-confirm');
      form = $("<form/>", {
        action: action,
        method: "post",
        data: {
          confirm: confirm
        }
      });
      form.append($("<input/>", {
        name: "authenticity_token",
        value: token,
        type: "hidden"
      }));
      return form.appendTo(document.body).submit();
    });
    $(".question_not_applicable").on("click", function () {
      var form, id, token;
      token = $('meta[name="csrf-token"]').attr('content');
      id = $("#item_id").val();
      form = $("<form/>", {
        action: id + "/question_not_applicable",
        method: "post",
        data: {
          confirm: "該当なしにしますか？"
        }
      });
      form.append($("<input/>", {
        name: "authenticity_token",
        value: token,
        type: "hidden"
      }));
      return form.appendTo(document.body).submit();
    });
    return $(".answered").on("click", function () {
      var form, id, token;
      token = $('meta[name="csrf-token"]').attr('content');
      id = $("#item_id").val();
      form = $("<form/>", {
        action: id + "/answered",
        method: "post",
        data: {
          confirm: "回答済みにしますか？"
        }
      });
      form.append($("<input/>", {
        name: "authenticity_token",
        value: token,
        type: "hidden"
      }));
      return form.appendTo(document.body).submit();
    });
  };

  Gws_Monitor_Topic.buildForm = function (action, confirm) {
    var checked, form, i, id, len, token;
    checked = $(".list-item input:checkbox:checked").map(function () {
      return $(this).val();
    });
    if (checked.length === 0) {
      return false;
    }
    token = $('meta[name="csrf-token"]').attr('content');
    form = $("<form/>", {
      action: action,
      method: "post",
      data: {
        confirm: confirm
      }
    });
    form.append($("<input/>", {
      name: "authenticity_token",
      value: token,
      type: "hidden"
    }));
    for (i = 0, len = checked.length; i < len; i++) {
      id = checked[i];
      form.append($("<input/>", {
        name: "ids[]",
        value: id,
        type: "hidden"
      }));
    }
    return form;
  };

  Gws_Monitor_Topic.renderForm = function (opts) {
    if (opts == null) {
      opts = {};
    }
    $("input.date").datetimepicker({
      lang: "ja",
      timepicker: false,
      format: 'Y/m/d',
      closeOnDateSelect: true,
      scrollInput: false,
      maxDate: opts["maxDate"]
    });
    return $("input.datetime").datetimepicker({
      lang: "ja",
      roundTime: 'ceil',
      step: 30,
      maxDate: opts["maxDate"]
    });
  };

  return Gws_Monitor_Topic;

})();
function Gws_Portal(selector, settings) {
  var options = {
    autogenerate_stylesheet: true,
    resize: {
      enabled: true,
      max_size: [4, 10]
    },
    widget_base_dimensions: ['auto', 120],
    widget_margins: [10, 10],
    min_cols: 1,
    max_cols: 4
  };
  if (settings && settings['readonly']) {
    this.readonly = true;
    options['resize'] = { enabled: false };
    options['draggable'] = { enabled: false, handle: 'disable' };
  }
  if (settings && settings['max_rows']) {
    options['max_rows'] = settings['max_rows'];
  }

  this.el = $(selector);
  this.gs = this.el.find("ul.portlets").gridster(options).data('gridster');
}

Gws_Portal.prototype.addItems = function(items) {
  var _this = this;
  $.each(items, function(idx, item) {
    _this.addItem(item);
  });
};

Gws_Portal.prototype.addItem = function(item) {
  var id = item._id.$oid;

  var li = this.gs.add_widget(
    '<li class="portlet-item" data-id="' + id + '"></li>',
    item.grid_data.size_x,
    item.grid_data.size_y,
    item.grid_data.col,
    item.grid_data.row
  );
  if (! li) {
    return;
  }
  li.data('id', id);

  var html = this.el.find(".portlet-html[data-id='" + id + "']");
  if (html.length) {
    var height = html.height();
    html.prependTo(li);
    //this.autoResizeItem(li, height);
  }
};

Gws_Portal.prototype.autoResizeItem = function(widget, height) {
  var base_y = this.gs.options.widget_base_dimensions[1];
  var extra  = ((height % base_y) > (base_y / 2)) ? 1 : 0;
  var size_x = widget.data('sizex');
  var size_y = Math.floor(height / base_y) + extra;

  if (widget.data('sizey') < size_y) {
    this.gs.resize_widget(widget, size_x, size_y);
  }
};

Gws_Portal.prototype.setSerializeEvent = function(selector) {
  var _this = this;
  _this.updateUrl = $(selector).data('href');
  $(selector).on("click", function() {
    _this.serialize();
  });
};

Gws_Portal.prototype.setResetEvent = function(selector) {
  var _this = this;
  $(selector).on("click", function() {
    var list = [];
    _this.el.find(".portlet-item").each(function(index) {
      list.push($(this).clone());
    });
    _this.gs.remove_all_widgets();

    $.each(list, function(index, li) {
      _this.gs.add_widget(li, li.data('sizex'), li.data('sizey'));
    });
  });
};

Gws_Portal.prototype.serialize = function() {
  var _this = this;
  var list = {};
  _this.el.find("li.portlet-item").each(function() {
    var li = $(this);
    var id = li.data('id');
    list[id] = _this.gs.serialize(li)[0];
  });

  $.ajax({
    url: _this.updateUrl,
    method: 'POST',
    dataType: 'json',
    data: {
      _method: 'put',
      authenticity_token: $('meta[name="csrf-token"]').attr('content'),
      json: JSON.stringify(list)
    },
    success: function(data) {
      SS.notice(data.message);
    }
  });
};
Gws_Elasticsearch_Highlighter = function () {
}

Gws_Elasticsearch_Highlighter.prototype = {
  render: function () {
    if (location.hash) {
      $(location.hash).css('border', '1px solid red');
    }
  }
}
;
this.Gws_Discussion_Thread = (function () {
  function Gws_Discussion_Thread() {
  }

  Gws_Discussion_Thread.render = function (user) {
    //temp file
    var appendSelectedFile = function (selected, fileId, humanizedName) {
      var span = $('<span></span>');
      var img = $('<img src="/assets/img/gws/ic-file.png" alt="" />');
      var a = $('<a target="_blank" rel="noopener"></a>');
      var input = $('<input type="hidden" name="item[file_ids][]" class="file-id" />');
      var icon = $("<i class=\"material-icons md-18 md-inactive deselect\">close</i>");

      span.attr("data-file-id", fileId);
      span.attr("id", "file-" + fileId);
      a.text(humanizedName);
      a.attr("href", "/.u" + user + "/apis/temp_files/" + fileId + "/view");
      input.attr("value", fileId);
      icon.on("click", function (e) {
        $(this).parent("span").remove();
        if ($(selected).find("[data-file-id]").length <= 0) {
          $(selected).hide();
        }
        return false;
      });

      span.append(img);
      span.append(a);
      span.append(icon);
      span.append(input);

      $(selected).show();
      $(selected).append(span);
    };

    $('a.ajax-box').data('on-select', function ($item) {
      var selected = $.colorbox.element().closest(".comment-files").find(".selected-files");
      var $data = $item.closest('[data-id]');
      var fileId = $data.data('id');
      var humanizedName = $data.data('humanized-name');
      appendSelectedFile(selected, fileId, humanizedName);
      return $.colorbox.close();
    });

    var options = {
      select: function (files, dropArea) {
        $(files).each(function (i, file) {
          var fileId, humanizedName, selected;
          selected = $(dropArea).closest(".comment-files").find(".selected-files");
          fileId = file["_id"];
          humanizedName = file["name"];
          return appendSelectedFile(selected, fileId, humanizedName);
        });
        return false;
      }
    };

    $(".comment-files .upload-drop-area").each(function() {
      new SS_Addon_TempFile(this, user, options);
    });

    // reply
    $(".open-reply").on('click', function () {
      $(this).closest(".addon-body").next(".reply").show();
      $(this).remove();
      return false;
    });

    //rely contriutor
    $(".reply[data-topic]").each(function () {
      var topic = $(this).attr("data-topic");
      var setContributor = function () {
        $('.discussion-contributor' + topic + ' input#item_contributor_model').val($(this).data('model'));
        $('.discussion-contributor' + topic + ' input#item_contributor_id').val($(this).data('id'));
        return $('.discussion-contributor' + topic + ' input#item_contributor_name').val($(this).data('name'));
      };
      $(this).find('.discussion-contributor' + topic + ' input[name="tmp[contributor]"]').on('change', setContributor);
      return $(this).find('.discussion-contributor' + topic + ' input[name="tmp[contributor]"]:checked').each(setContributor);
    });
  };

  return Gws_Discussion_Thread;

})();
this.Gws_Discussion_Unseen = (function () {
  function Gws_Discussion_Unseen() {
  }

  Gws_Discussion_Unseen.url = null;

  Gws_Discussion_Unseen.intervalID = null;

  Gws_Discussion_Unseen.intervalTime = null;

  Gws_Discussion_Unseen.timestamp = null;

  Gws_Discussion_Unseen.renderUnseen = function (url, intervalTime, timestamp) {
    this.url = url;
    this.intervalTime = intervalTime;
    this.timestamp = timestamp;
    if (this.url && this.intervalTime && this.timestamp) {
      return this.intervalID = setInterval(this.checkMessage, this.intervalTime);
    }
  };

  Gws_Discussion_Unseen.checkMessage = function () {
    return $.ajax({
      url: Gws_Discussion_Unseen.url,
      success: function (data, status) {
        var timestamp;
        timestamp = parseInt(data);
        if (timestamp > Gws_Discussion_Unseen.timestamp) {
          $(".gws-discussion-unseen").show();
          return clearInterval(Gws_Discussion_Unseen.intervalID);
        }
      }
    });
  };

  return Gws_Discussion_Unseen;

})();
Gws_Attendance = function (el, options) {
  this.el = el;
  this.$el = $(el);
  this.$toolbar = this.$el.find('.cell-toolbar');
  this.options = options;
  this.now = new Date(options.now);
  this.render();
};

Gws_Attendance.prototype.render = function() {
  var _this = this;

  this.$el.find('button[name=punch]').on('click', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    var action = $(this).data('action');
    var confirm = $(this).data('confirm');
    _this.onPunchClicked(action, confirm);
  });

  this.$el.find('button[name=edit]').on('click', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    var action = $(this).data('action');
    var confirm = $(this).data('confirm');
    _this.onEditClicked(action, confirm);
  });

  this.$el.find('.reason-tooltip').on('click', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    _this.hideToolbar();
    _this.hideTooltip();
    $(this).find('.reason').show();
  });

  this.$el.find('select[name=year_month]').on('change', function() {
    var val = $(this).val();
    if (! val) {
      return;
    }
    location.href = _this.options.indexUrl.replace(':year_month', val);
  });

  this.$toolbar.find(".punch").on("click", function() {
    _this.onPunchClicked($(this).attr("href"), $(this).data("confirmation"));
    return false;
  });

  $(document).on('click', this.el + ' .time-card .time', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    _this.onClickTime($(this));
  });

  $(document).on('click', this.el + ' .time-card .memo', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    _this.onClickMemo($(this));
  });

  $(document).on('click', function() {
    _this.hideToolbar();
    _this.hideTooltip();
  });
};

Gws_Attendance.prototype.onPunchClicked = function(action, message) {
  if (! action) {
    return
  }

  if (message) {
    if (! confirm(message)) {
      return;
    }
  }

  var token = $('meta[name="csrf-token"]').attr('content');

  $form = $('<form/>', { action: action, method: 'post' });
  $form.append($("<input/>", { name: "authenticity_token", value: token, type: "hidden" }));
  $('body').append($form);
  $form.submit();
};

Gws_Attendance.prototype.onEditClicked = function(action, message) {
  if (!action) {
    return
  }

  if (message) {
    if (!confirm(message)) {
      return;
    }
  }

  $a = $('<a />', { href: action });
  $a.colorbox({ open: true, width: '90%' });
};

Gws_Attendance.prototype.hideToolbar = function() {
  this.$toolbar.hide();
};

Gws_Attendance.prototype.hideTooltip = function() {
  this.$el.find('.reason-tooltip .reason').hide();
};

Gws_Attendance.prototype.onClickTime = function($cell) {
  this.onClickCell($cell, this.options.timeUrl);
};

Gws_Attendance.prototype.onClickMemo = function($cell) {
  this.onClickCell($cell, this.options.memoUrl);
};

Gws_Attendance.prototype.setFocus = function($cell) {
  this.$el.find('.time-card .time').removeClass('focus');
  this.$el.find('.time-card .memo').removeClass('focus');
  $cell.addClass('focus');
};

Gws_Attendance.prototype.isCellToday = function($cell) {
  return $cell.closest('tr').hasClass('current');
};

Gws_Attendance.prototype.onClickCell = function($cell, urlTemplate) {
  this.hideTooltip();

  if (! $cell.data('day')) {
    return;
  }

  this.setFocus($cell);

  if (!this.options.editable && !this.isCellToday($cell)) {
    this.$toolbar.hide();
    return;
  }

  var day = $cell.data('day');
  var type = $cell.data('type');
  var mode = $cell.data('mode');

  var punchable = this.isCellToday($cell);
  var editable = this.options.editable;

  if (type === "memo") {
    if (this.isCellToday($cell)) {
      editable = true;
    }
  }

  var showsToolbar = false;
  if (mode === "punch" && punchable && this.options.punchUrl) {
    var url = this.options.punchUrl;
    url = url.replace(':type', type);

    this.$toolbar.find('.edit').hide();
    this.$toolbar.find('.punch').attr('href', url).show();
    showsToolbar = true;
  }

  if (mode === "edit" && editable) {
    var url = urlTemplate;
    url = url.replace(':day', day);
    url = url.replace(':type', type);

    this.$toolbar.find('.punch').hide();
    this.$toolbar.find('.edit').attr('href', url).show();
    showsToolbar = true;
  }

  if (! showsToolbar) {
    this.$toolbar.hide();
    return;
  }

  var offset = $cell.offset();
  if ($cell.hasClass('top')) {
    offset.top -= this.$toolbar.outerHeight();
  } else {
    offset.top += $cell.outerHeight();
  }

  // call `show` and then call `offset`. order is important
  this.$toolbar.show();
  this.$toolbar.offset(offset);
};
Gws_Attendance_Portlet = function (el, options) {
  // this.el = el;
  this.$el = $(el);
  // this.$toolbar = this.$el.find('.cell-toolbar');
  this.options = options;
  // this.now = new Date(options.now);
  this.render();
};

Gws_Attendance_Portlet.prototype.render = function() {
  var _this = this;

  this.$el.find('button[name=punch]').on('click', function() {
    _this.punch($(this), $(this).closest('tr').data('field-name'));
  });

  this.$el.find('button[name=edit]').on('click', function() {
    _this.edit($(this), $(this).closest('tr').data('field-name'));
  });
};

Gws_Attendance_Portlet.prototype.punch = function($button, fieldName) {
  $button.attr('disabled', 'disabled');
  if (! confirm(this.options.confirmMessage)) {
    $button.removeAttr('disabled');
    return;
  }

  var url = this.options.punchUrl.replace(':TYPE', fieldName);
  var _this = this;
  $.ajax({
    url: url,
    method: 'POST',
    data: { ref: this.options.ref },
    dataType: 'json',
    success: function(data) {
      alert(_this.options.successMessage);
      location.reload();
    },
    error: function(xhr, status, error) {
      alert(xhr.responseJSON.join("\n"));
    },
    complete: function() {
      $button.removeAttr('disabled');
    }
  });
};

Gws_Attendance_Portlet.prototype.edit = function($button, fieldName) {
  $button.attr('disabled', 'disabled');

  var url = this.options.editUrl.replace(':TYPE', fieldName);
  $a = $('<a/>', { href: url });
  $a.colorbox({
    open: true,
    onClosed: function() { $button.removeAttr('disabled'); }
  });
};
this.Gws_Presence_User = (function () {
  function Gws_Presence_User() {}

  Gws_Presence_User.render = function () {
    // selector
    $(document).on("click", function() {
      $(".presence-state-selector").hide();
        return true;
    });
    $(".presence-state-selector").on("click", function() {
      return false;
    });
    $(".presence-state-selector [data-value]").on("click", function() {
      var id = $(this).closest(".presence-state-selector").attr("data-id");
      var url = $(this).closest(".presence-state-selector").attr("data-url");
      var value = $(this).attr("data-value");
      $.ajax({
        url: url,
        type: "POST",
        data: {
          _method: 'put',
          authenticity_token: $('meta[name="csrf-token"]').attr('content'),
          presence_state: value,
        },
        success: function(data) {
          Gws_Presence_User.changedState(id, data);
          $(".presence-state-selector").hide();
        },
        error: function (xhr, status, error) {
          alert(xhr.responseJSON.join("\n"));
        },
      });
      return false;
    });
    $(".editable .select-presence-state,.editable .presence-state").on("click", function(){
      $(".presence-state-selector").closest("li.portlet-item").css("z-index", 0);
      $(".presence-state-selector").hide();
      $(this).closest("li.portlet-item").css("z-index", 1000);
      $(this).closest("td").find(".presence-state-selector").show();
      return false;
    });
    // ajax-text-field
    $(".ajax-text-field").on("click", function(){
      Gws_Presence_User.toggleForm(this);
      return false;
    });
    $(".ajax-text-field").next(".editicon").on("click", function(){
      $(this).prev(".ajax-text-field").trigger('click');
      return false;
    })
  };

  Gws_Presence_User.changedState = function (id, data) {
    var presence_state = data["presence_state"] || "";
    var presence_state_label = data["presence_state_label"];
    var presence_state_style = data["presence_state_style"];
    var state = $("tr[data-id=" + id + "] .presence-state");
    var selector = $("tr[data-id=" + id + "] .presence-state-selector");

    state.removeClass();
    state.addClass('presence-state');
    state.addClass(presence_state_style);
    state.text(presence_state_label);

    selector.find('[data-value="' + presence_state + '"] .selected-icon').css('visibility', 'visible');
    selector.find('[data-value!="' + presence_state + '"] .selected-icon').css('visibility', 'hidden');
  }

  Gws_Presence_User.toggleForm = function (ele) {
    var state = $(ele).attr("data-tag-state");
    var original = $(ele).attr("data-original-tag");
    var form = $(ele).attr("data-form-tag");
    var value = $(ele).text() || $(ele).val();
    var name = $(form).attr("name");
    var id = $(form).attr("data-id");
    var url = $(form).attr("data-url");
    var errorOccurred = false;

    if (state == "original") {
      form = $(form);
      form.attr("data-original-tag", $(ele).attr("data-original-tag"));
      form.attr("data-form-tag", $(ele).attr("data-form-tag"));
      form.val(value);
      form.focusout(function (e) {
        if (errorOccurred) {
          return true;
        }
        var data = {
          _method: 'put',
          authenticity_token: $('meta[name="csrf-token"]').attr('content'),
        };
        data[name] = $(form).val();
        $.ajax({
          url: url,
          type: "POST",
          data: data,
          success: function(data) {
            $(form).val(data[name]);
            Gws_Presence_User.toggleForm(form);
          },
          error: function (xhr, status, error) {
            alert(xhr.responseJSON.join("\n"));
            errorOccurred = true;
          },
        });
        return false;
      });
      form.keypress(function (e) {
        if (e.which == SS.KEY_ENTER) {
          var data = {
            _method: 'put',
            authenticity_token: $('meta[name="csrf-token"]').attr('content'),
          };
          data[name] = $(form).val();
          $.ajax({
            url: url,
            type: "POST",
            data: data,
            success: function(data) {
              $(form).val(data[name]);
              Gws_Presence_User.toggleForm(form);
            },
            error: function (xhr, status, error) {
              alert(xhr.responseJSON.join("\n"));
              errorOccurred = true;
            },
          });
          return false;
        }
      });
      var replaced = form.uniqueId();
      $(ele).replaceWith(form);
      $(replaced).focus();
    }
    else {
      original = $(original).text(value);
      original.attr("data-original-tag", $(ele).attr("data-original-tag"));
      original.attr("data-form-tag", $(ele).attr("data-form-tag"));
      original.on("click", function(){
        Gws_Presence_User.toggleForm(this);
        return false;
      });
      original.uniqueId();
      $(ele).replaceWith(original);

      // support same name's ajax-text-field
      $(".ajax-text-field[data-id='" + original.attr("data-id") + "'][data-name='" + original.attr("data-name") + "']").text(value);
    }
  };

  return Gws_Presence_User;
})();

this.Gws_Presence_User_Reload = (function () {
  function Gws_Presence_User_Reload() {}

  Gws_Presence_User_Reload.render = function (opts) {
    if (opts == null) {
      opts = {};
    }

    var table_url = opts["url"];
    var paginate_params = opts["paginate_params"];
    var page = opts["page"];

    $(".group-users .reload").on("click", function () {
      param = $.param({
        "s": {"keyword": $(".group-users [name='s[keyword]']").val()},
        "paginate_params": paginate_params,
        "page": page
      });
      $.ajax({
        url: table_url + '?' + param,
        beforeSend: function () {
          $(".group-users .data-table-wrap").html(SS.loading);
        },
        success: function (data) {
          $(".group-users .data-table-wrap").html(data);
          var time = $(".group-users .data-table-wrap").find("time");
          $(".group-users .list-head time").replaceWith(time).show();
          time.show();
        }
      });
    });
    $(".group-users .list-head .search").on("submit", function () {
      param = $.param({
        "s": {"keyword": $(".group-users [name='s[keyword]']").val()},
        "paginate_params": paginate_params,
      });
      $.ajax({
        url: table_url + '?' + param,
        beforeSend: function () {
          $(".group-users .data-table-wrap").html(SS.loading);
        },
        success: function (data) {
          $(".group-users .data-table-wrap").html(data);
          var time = $(".group-users .data-table-wrap").find("time");
          $(".group-users .list-head time").replaceWith(time);
          time.show();
        },
        error: function (xhr, status, error) {
          $(".group-users .data-table-wrap").html("");
        }
      });
      return false;
    });
  }

  return Gws_Presence_User_Reload;
})();
function Gws_Share_FolderToolbar(el, options) {
  this.$el = $(el);
  this.options = options;
  this.render();
}

Gws_Share_FolderToolbar.prototype.render = function () {
  var self = this;

  this.$el.find(".btn-create-folder").on("click", function() {
    self.createFolder($(this));
  });

  this.$el.find(".btn-create-root-folder").on("click", function() {
    self.createFolder($(this));
  });

  this.$el.find(".btn-rename-folder").on("click", function() {
    self.renameFolder($(this), { success: { callback: self.refresh } });
  });

  this.$el.find(".btn-delete-folder").on("click", function() {
    self.deleteFolder($(this));
  });

  this.$el.find(".btn-edit-folder").on("click", function() {
    self.editFolder($(this));
  });

  this.$el.find(".btn-refresh-folder").on("click", function() {
    self.refreshFolder();
  });
};

Gws_Share_FolderToolbar.prototype.createFolder = function ($button, options) {
  var href = $button.data("href");
  if (href) {
    location.href = href;
    return;
  }

  var api = $button.data("api");
  if (! api) {
    return;
  }

  var success = $button.data("success");
  if (! success && options) {
    success = options.success;
  }
  var error = $button.data("error");
  if (! error && options) {
    error = options.error;
  }

  var self = this;

  $.colorbox({
    href: api, open: true, fixed: true, with: "90%", height: "90%",
    onComplete: function() {
      SS.ajaxForm("#cboxLoadedContent form", {
        success: function(data) {
          $.colorbox.close();
          if (success && success.redirect_to) {
            var id;
            if (data) {
              id = data.id;
              if (! id) {
                id = data._id;
              }
            }

            location.href = success.redirect_to.replace(/:id/, id);
            return;
          }
          if (success && success.reload) {
            location.reload();
            return;
          }
          if (success && success.callback) {
            success.callback.call(self, data);
          }
        },
        error: function(xhr) {
          $.colorbox.close();

          if (xhr.responseJSON && xhr.responseJSON.length > 0) {
            alert(xhr.responseJSON.join("\n"));
          } else if (error && error.message) {
            alert(error.message);
          }
        }
      });
    }
  });
};

Gws_Share_FolderToolbar.prototype.refresh = function (data) {
  if (! data) {
    return;
  }

  this.$el.find(".folder-name").text(data.name);
  this.refreshFolder();
};

Gws_Share_FolderToolbar.prototype.renameFolder = Gws_Share_FolderToolbar.prototype.createFolder;
Gws_Share_FolderToolbar.prototype.deleteFolder = Gws_Share_FolderToolbar.prototype.createFolder;
Gws_Share_FolderToolbar.prototype.editFolder = Gws_Share_FolderToolbar.prototype.createFolder;

Gws_Share_FolderToolbar.prototype.refreshFolder = function () {
  if (!this.options.treeNavi) {
    return;
  }

  this.options.treeNavi.refresh();
};






























$(function () {
  // external link
  $('a[href^=http]').not('[href*="' + location.hostname + '"]').attr({ target: '_blank', rel: "noopener" });

  // tabs
  var path = location.pathname + "/";
  $(".gws-schedule-tabs a").each(function () {
    var menu = $(this);
    if (path.match(new RegExp('^' + menu.attr('href') + '(\/|$)'))) {
      menu.addClass("current");
    }
  });

  Gws_Member.render();
});
