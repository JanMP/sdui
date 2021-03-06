Package.describe({
  name: 'janmp:sdui',
  version: '0.0.2',
  // Brief, one-line summary of the package.
  summary: 'Some high level React components and setup for backend.',
  // URL to the Git repository containing the source code for this package.
  git: 'http://github.com/JanMP/sdui',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('2.5.1');
  api.use('ecmascript');
  api.use('coffeescript@2.4.1');
  api.use('typescript');
  api.use('reactive-var');
  api.use('alanning:roles@3.4.0');
  api.use('mdg:validated-method@1.2.0');
  api.use('momentjs:moment@2.29.1');
  api.use('peerlibrary:reactive-publish@0.10.0');
  api.use('tunguska:reactive-aggregate@1.3.7');
  api.addFiles('css/sdui.css', 'client');
  api.mainModule('sdui-client.coffee', 'client');
  api.mainModule('sdui-server.coffee', 'server');
});

Package.onTest(function(api) {
  api.use('ecmascript');
  api.use('tinytest');
  api.use('janmp:sdui');
  api.mainModule('sdui-tests.js');
});
