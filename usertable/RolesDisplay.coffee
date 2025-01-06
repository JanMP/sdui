import React, {useState, useEffect, useContext} from 'react'
import connectFieldPlus from '../forms/connectFieldPlus.coffee'
import {UseTracker, useSubscribe} from 'meteor/react-meteor-data'
import {MultiSelect} from 'primereact/multiselect'
import {meteorApply} from '../common/meteorApply.coffee'
import _ from 'lodash'


export RolesDisplay = ({row, measure}) ->
  <span>
    {
      row.roles
      .map (r) ->
        "#{r.scope ? 'GLOBAL'}:#{r.role?._id}"
      .join(', ')
    }
  </span>