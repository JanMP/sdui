// Import Tinytest from the tinytest Meteor package.
import { Tinytest } from "meteor/tinytest";

// Import and rename a variable exported by sdui.js.
import { name as packageName } from "meteor/sdui";

// Write your tests here!
// Here is an example.
Tinytest.add('sdui - example', function (test) {
  test.equal(packageName, "sdui");
});
