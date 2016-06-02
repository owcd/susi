/*define('lodash', ['exports'], function(__exports__) {
    __exports__['default'] = window._;
});*/

define('moment', ['exports'], function(__exports__) {
    __exports__['default'] = window.moment;
});

define('sprintf', ['exports'], function(__exports__) {
    //console.log("PB", window.ProgressBar)
    __exports__['default'] = window.sprintf;
    __exports__['vsprintf'] = window.vsprintf;
});
