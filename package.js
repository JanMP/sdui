Package.describe({
  name: 'janmp:sdui',
  version: '2.0.0',
  // Brief, one-line summary of the package.
  summary: 'Some high level React components and setup for backend.',
  // URL to the Git repository containing the source code for this package.
  git: 'http://github.com/JanMP/sdui',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('2.10.0');
  api.use('ecmascript');
  api.use('coffeescript@2.7.0');
  api.use('typescript');
  api.use('zodern:types');
  api.use('reactive-var');
  api.use('alanning:roles@3.4.0');
  api.use('mdg:validated-method');
  api.use('peerlibrary:reactive-publish');
  api.use('tunguska:reactive-aggregate');
  // api.use('mizzao:user-status@1.0.1'); 
  api.mainModule('sdui-client-dynamic.coffee', 'client');
  api.mainModule('sdui-server.coffee', 'server');
});

Package.onTest(function(api) {
  api.use('ecmascript');
  api.use('tinytest');
  api.use('janmp:sdui');
  api.mainModule('sdui-tests.js');
});
