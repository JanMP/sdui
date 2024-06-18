import React, {useEffect, useState} from 'react'
import {SdTable} from '../tables/SdTable.coffee'
import {meteorApply} from '../common/meteorApply.coffee'
import {AllowedRolesContext} from './AllowedRolesContext.coffee'
import _ from 'lodash'

selectOptionFor = ({role, scope}) ->
  value: {role, scope}
  label: "#{scope ? 'GLOBAL'}: #{role}"

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

export SdUserTable = ({dataOptions}) ->
  [roleSelectOptions, setRoleSelectOptions] = useState []

  useEffect ->
    meteorApply
      method: 'users.getAllowedRoles'
      data: {}
    .then allowedRolesToOptions
    .then setRoleSelectOptions
    .catch console.error
    undefined
  , []

  <AllowedRolesContext.Provider value={roleSelectOptions}>
    <SdTable dataOptions={dataOptions} />
  </AllowedRolesContext.Provider>