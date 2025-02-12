import {Meteor} from 'meteor/meteor'


###*
  @param {Object} dataOptions
  @param {String} dataOptions.sourceName
  @param {[Object]} dataOptions.sourceArray
  @param {Function} dataOptions.toolbarStart
  @returns {Object} {dataOptions}
  ###
export createAppLayoutAPI = ({
  sourceName, sourceArray, toolbarStart = -> null
  routerLess = false
}) ->
  {sourceName, sourceArray, toolbarStart, routerLess}

