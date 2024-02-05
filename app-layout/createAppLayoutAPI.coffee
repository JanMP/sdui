import {Meteor} from 'meteor/meteor'
import {BrowserRouter as Router, Routes, Route, useLocation, useNavigate} from 'react-router-dom'
import _ from 'lodash'


###*
  @param {object} dataOptions
  @param {string} dataOptions.sourceName
  @param {[object]} dataOptions.sourceArray
  @returns {object} {dataOptions}
  ###
export createAppLayoutAPI = ({
  sourceName, sourceArray
}) ->
  
  {sourceName, sourceArray}

