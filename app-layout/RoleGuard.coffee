import React from 'react'
import {Outlet} from 'react-router-dom'
import {useCurrentUserIsInRole} from 'meteor/janmp:sdui'

export AccessDeniedPage = ->
  <div className="p-card p-component p-8">
    <h1>Access Denied</h1>
    <p>Sie haben nicht die nötigen Zugriffsrechte für diese Seite.</p>
  </div>

export RoleGuard = ({role}) ->

  isAllowed = useCurrentUserIsInRole role

  if isAllowed
    <Outlet/>
  else
    <AccessDeniedPage/>