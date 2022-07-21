import React, {useEffect, useState} from 'react'
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms'
import Select from 'react-select'
import {meteorApply} from '../common/meteorApply.coffee'
import {UseTracker, useSubscribe} from 'meteor/react-meteor-data'
import _ from 'lodash'


selectOptionFor = ({role, scope}) ->
  value: {role, scope}
  label: "#{scope ? 'GLOBAL'}: #{role}"

allowedRolesToOptions = (allowedRoles) ->
  globalOptions = allowedRoles.global.map (role) -> selectOptionFor {role}
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

  [options, setOptions] = useState value: null, label: 'loading allowed roles'

  useEffect ->
    meteorApply
      method: 'user.getAllowedRoles'
      data: {}
    .then allowedRolesToOptions
    .then setOptions
  , []

  valueOptions = row.roles.map (r) -> selectOptionFor role: r.role._id, scope: r.scope

  onChange = (value, change) ->
    console.log {value, change}
    meteorApply
      method: 'user.onChangeRoles'
      data:
        id: row._id
        value: value
        change: change


  if mayEdit
    <Select
      value={valueOptions}
      options={options}
      onChange={onChange}
      name="roles"
      isMulti
    />
  else
    <div>{value.join ', '}</div>
