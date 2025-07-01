Package.describe({
  name: 'janmp:sdui',
  version: '1.1.0',
  // Brief, one-line summary of the package.
  summary: 'Some high level React components and setup for backend.',
  // URL to the Git repository containing the source code for this package.
  git: 'http://github.com/JanMP/sdui',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom(['2.16', '3.3']);
  api.use('ecmascript');
  api.use('coffeescript@2.7.1-rc300.0');
  api.use('typescript@5.6.3');
  api.use('zodern:types@1.0.13');
  api.use('reactive-var');
  api.use('alanning:roles@4.0.0');
  api.use('mdg:validated-method@1.3.0');
  api.use('mdg:validation-error');
  // api.use('peerlibrary:reactive-publish@0.10.0');
  api.use('tunguska:reactive-aggregate@2.0.2');
  api.use('msavin:sjobs');
  api.use('mizzao:user-status@2.0.0-rc.2');
  api.mainModule('sdui-client-dynamic.coffee', 'client');
  api.mainModule('sdui-server.coffee', 'server');
});

Package.onTest(function(api) {
  api.use('ecmascript');
  api.use('coffeescript@2.7.1-rc300.0');
  api.use('react-meteor-data');
  api.use('tinytest');
  api.use('janmp:sdui');
  api.mainModule('sdui-tests.js');
});
