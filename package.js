Package.describe({
  name: 'janmp:sdui',
  version: '1.0.0',
  // Brief, one-line summary of the package.
  summary: 'Some high level React components and setup for backend.',
  // URL to the Git repository containing the source code for this package.
  git: 'http://github.com/JanMP/sdui',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom(['2.16', '3.0-rc.4']);
  api.use('ecmascript');
  api.use('coffeescript@2.7.0');
  api.use('typescript');
  api.use('zodern:types@1.0.9');
  api.use('reactive-var');
  api.use('alanning:roles@4.0.0-alpha.3');
  api.use('mdg:validated-method@1.2.0');
  // api.use('peerlibrary:reactive-publish@0.10.0');
  api.use('tunguska:reactive-aggregate@2.0.0');
  api.use('aldeed:simple-schema@2.0.0-rc300.1');
  api.use('msavin:sjobs');
  api.use('mizzao:user-status@2.0.0-rc.2'); 
  api.mainModule('sdui-client-dynamic.coffee', 'client');
  api.mainModule('sdui-server.coffee', 'server');
});

Package.onTest(function(api) {
  api.use('ecmascript');
  api.use('tinytest');
  api.use('janmp:sdui');
  api.mainModule('sdui-tests.js');
});
