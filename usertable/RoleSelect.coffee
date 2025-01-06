import React, {useState, useEffect, useContext} from 'react'
import connectFieldPlus from '../forms/connectFieldPlus.coffee'
import {UseTracker, useSubscribe} from 'meteor/react-meteor-data'
import {MultiSelect} from 'primereact/multiselect'
import {meteorApply} from '../common/meteorApply.coffee'
import _ from 'lodash'

import {AllowedRolesContext} from './AllowedRolesContext.coffee'

optionFromValue = (value) ->
  # check if it isn't transformed yet
  if value?[0]?._id?
    value.map (rolesRow) ->
      {role, scope} = rolesRow
      {role: role._id, scope}
  else value

RoleSelect = ({name, value, onChange, readOnly, disabled, props...}) ->
  
  options = useContext AllowedRolesContext

  handleChange = (e) -> onChange e.value


  <MultiSelect
    value={optionFromValue value}
    options={options}
    onChange={handleChange}
    name={name}
    style={maxWidth: '100%', minWidth: '100%'}
  />

export RoleSelectField =  connectFieldPlus RoleSelect