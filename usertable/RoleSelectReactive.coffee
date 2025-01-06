import React, {useState, useEffect, useContext} from 'react'
import connectFieldPlus from '../forms/connectFieldPlus.coffee'
import {UseTracker, useSubscribe} from 'meteor/react-meteor-data'
import {MultiSelect} from 'primereact/multiselect'
import {meteorApply} from '../common/meteorApply.coffee'
import _ from 'lodash'

import {AllowedRolesContext} from './AllowedRolesContext.coffee'

valueFromRow = (row) ->
  row.roles.map (rolesRow) ->
    {role, scope} = rolesRow
    {role: role._id, scope}


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
export RoleSelectReactive = ({row, columnKey, schemaBridge, onChangeField, measure, mayEdit}) ->

  options = useContext AllowedRolesContext

  onChange = ({value}) ->
    meteorApply
      method: 'user.onChangeRoles'
      data:
        id: row._id
        value: value

  rolesList = '# TODO implement text rendering of roles from row'

  if mayEdit or true
    if on
      <MultiSelect
        value={valueFromRow row}
        options={options}
        onChange={onChange}
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