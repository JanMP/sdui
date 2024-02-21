import {Meteor} from 'meteor/meteor'


###*
  @param {object} dataOptions
  @param {string} dataOptions.sourceName
  @param {[object]} dataOptions.sourceArray
  @param {function} dataOptions.toolbarStart
  @returns {object} {dataOptions}
  ###
export createAppLayoutAPI = ({
  sourceName, sourceArray, toolbarStart = -> null
  routerLess = false
}) ->
  {sourceName, sourceArray, toolbarStart, routerLess}

