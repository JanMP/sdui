import React from 'react'
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms'
import Select from 'react-select'
import {meteorApply} from '../common/meteorApply.coffee'

stringToOption = (str) ->
  value: str
  label: str

export RoleSelect = ({allowedRoles}) -> ({row, columnKey, schemaBridge, onChangeField, measure, mayEdit}) ->

  allowedRoles ?= ['admin', 'user']
  value = row.roles
  options = allowedRoles.map stringToOption
  valueOptions = value.map stringToOption

  onChange = (value, change) ->
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
