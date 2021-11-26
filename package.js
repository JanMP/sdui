Package.describe({
  name: 'janmp:sdui',
  version: '0.0.1',
  // Brief, one-line summary of the package.
  summary: '',
  // URL to the Git repository containing the source code for this package.
  git: '',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('2.5');
  api.use('ecmascript');
  api.use('coffeescript');
  api.use('typescript');
  api.use('reactive-var');
  api.use('alanning:roles');
  api.use('mdg:validated-method');
  api.use('momentjs:moment');
  api.use('peerlibrary:reactive-publish');
  api.use('tunguska:reactive-aggregate');
  api.mainModule('sdui-client.coffee', 'client');
  api.mainModule('sdui-server.coffee', 'server');
});

Package.onTest(function(api) {
  api.use('ecmascript');
  api.use('tinytest');
  api.use('sdui');
  api.mainModule('sdui-tests.js');
});
