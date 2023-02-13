import React, {useEffect, useState} from 'react'
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms'
import {MultiSelect} from 'primereact/multiselect'
import {meteorApply} from '../common/meteorApply.coffee'
import {UseTracker, useSubscribe} from 'meteor/react-meteor-data'
import _ from 'lodash'


selectOptionFor = ({role, scope}) ->
  value: {role, scope}
  label: "#{scope ? 'GLOBAL'}: #{role}"

valueFromRow = (row) ->
  row.roles.map (rolesRow) ->
    {role, scope} = rolesRow
    {role: role._id, scope}

allowedRolesToOptions = (allowedRoles) ->
  globalOptions = allowedRoles.global.map (role) -> selectOptionFor {role, scope: null}
  scopedOptions =
    _(allowedRoles.scope)
    .keys()
    .sortBy()
    .map (scope) ->
      allowedRoles.scope[scope].map (role) ->
        selectOptionFor {role, scope}
    .flatten()
    .value()
  [globalOptions..., scopedOptions...]


export RoleSelect = ({row, columnKey, schemaBridge, onChangeField, measure, mayEdit}) ->

  [options, setOptions] = useState null

  useEffect ->
    meteorApply
      method: 'user.getAllowedRoles'
      data: {}
    .then allowedRolesToOptions
    .then setOptions
    return
  , []

  onChange = (value) ->
    console.log {value}
    meteorApply
      method: 'user.onChangeRoles'
      data:
        id: row._id
        value: value


  if mayEdit
    if on
      <MultiSelect
        value={valueFromRow row}
        options={options}
        onChange={(e) -> onChange e.value}
        name="roles"
      />
    else
      <div>
        <pre>
         {JSON.stringify {valueOptions, options}, null, 2}
        </pre>
      </div>
  else
    <div>{rolesList}</div>
