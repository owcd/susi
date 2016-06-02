/*jshint node:true*/
/* global require, module */
var EmberApp = require('ember-cli/lib/broccoli/ember-app');
var Funnel = require('broccoli-funnel');
var coffee = require('broccoli-coffee');
var less = require('broccoli-less-single');

styleCss = function(){
    var inputTree  = new Funnel('app/styles/', {
        include: ['susi.less', '_skeleton.less', 'application/*.less', 'bootstrap/*.less', 'lib/*.less']
    });
    var options = {
        paths: ['bower_components/bootstrap/less']
    }

    return less(inputTree, 'susi.less', 'assets/susi.css', options);
}

module.exports = function (defaults) {
    var app = new EmberApp(defaults, {
        sourcemaps: { enabled: false },
        lessOptions: {
            paths: [
                'bower_components/bootstrap/less'
            ]
        }
    });

    // import libraries
    app.import('bower_components/lodash/lodash.js');
    app.import('bower_components/bootstrap/dist/js/bootstrap.min.js');
    app.import('bower_components/moment/moment.js');
    app.import('bower_components/moment-duration-format/lib/moment-duration-format.js');
    app.import({
        development: 'bower_components/sprintf/src/sprintf.js',
        production: 'bower_components/sprintf/dist/sprintf.min.js'
    });

    //shims for previously imported
    app.import('vendor/shims.js', {
        'moment': ['default']
    });

    return app.toTree([styleCss()]);
};
