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

###*
 * RoleSelect component for assigning roles to users. This component displays a multiselect dropdown
 * that allows the selection of multiple roles for a user. The roles can be either global or scoped to specific areas.
 * Upon selection, the new roles are updated for the user through a Meteor method call.
 * This component leverages the uniforms package for React for form handling.
 *
 * @param {Object} props The component props.
 * @param {Object} props.row The data row corresponding to the current user, containing ids and roles.
 * @param {String} props.columnKey The key corresponding to the current column in the data table.
 * @param {Object} props.schemaBridge An object provided by uniforms to bridge the schema.
 * @param {Function} props.onChangeField A callback function to call when the field value changes.
 * @param {Function} props.measure A function for measure calculations, not utilized in the current implementation.
 * @param {Boolean} props.mayEdit A flag indicating if the current user can edit roles.
 * @returns {React.Element} The RoleSelect component rendering a MultiSelect dropdown or a simple div based on the editing permissions.
###
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

  rolesList = 'Fnord'

  if mayEdit
    if on
      <MultiSelect
        value={valueFromRow row}
        options={options}
        onChange={(e) -> onChange e.value}
        name="roles"
        style={maxWidth: '100%', minWidth: '100%'}
      />
    else
      <div>
        <pre>
         {JSON.stringify {options, value: valueFromRow row}, null, 2}
        </pre>
      </div>
  else
    <div>{rolesList}</div>
