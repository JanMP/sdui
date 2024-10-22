import {Meteor} from 'meteor/meteor'
import {BrowserRouter as Router, Routes, Route, useLocation, useNavigate, useRoutes} from 'react-router-dom'
import React, {useState} from 'react'
import {BreadCrumb} from 'primereact/breadcrumb'
import {PanelMenu} from 'primereact/panelmenu'
import {Sidebar} from 'primereact/sidebar'
import {TieredMenu} from 'primereact/tieredmenu'
import {AppToolbar} from './AppToolbar.coffee'
import {PathNotFound} from './PathNotFound.coffee'
import {LoginPage} from './LoginPage.coffee'
import {ResetPasswordPage} from './ResetPasswordPage.coffee'
import {VerifyEmailPage} from './VerifyEmailPage.coffee'
import {RoleGuard, AccessDeniedPage} from './RoleGuard.coffee'
import {useCurrentUserIsInRole} from '../common/roleChecks.coffee'

isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test navigator.userAgent

import _ from 'lodash'

defaultRoutes = [
  label: 'Login', path: '/login', element: <LoginPage/>
,
  label: 'Reset Password', path: '/reset-password/:token', element: <ResetPasswordPage/>
,
  label: 'Verify Email', path: '/verify-email/:token', element: <VerifyEmailPage/>
,
  label: '404', path: '*', element: <PathNotFound/>
]

MainMenu = ({sourceArray, sidebarIsVisible, onCloseSidebar}) ->
  navigate = useNavigate()
  
  classNameForPath = (path) ->
    if location.pathname is path
      'border-primary-500 border-1'
    else
      ''

  processMenuItems = (items, parentPath) ->
    
    _(items).map (item) ->
      if item.path
        if parentPath
          item.path = parentPath + '/' + item.path
      if item.items
        item.items = processMenuItems item.items, item.path
      else
        item.command = ->
          navigate item.path
          onCloseSidebar?()
      item.className = classNameForPath item.path
      item.disabled = item.disabled or if item.role then not useCurrentUserIsInRole item.role else false
      item unless item.disabled and item.hideOnDisabled
    .compact()
    .value()

  menuItems = processMenuItems _.cloneDeep sourceArray

  if isMobile
    <Sidebar visible={sidebarIsVisible} onHide={onCloseSidebar}>
      <PanelMenu model={menuItems} className="h-full"/>
    </Sidebar>
  else
    <TieredMenu model={menuItems} className="h-full"/>


MainRoutes = ({sourceArray}) ->
  processRoutes = (items) ->
    items.map (item) ->
      if item.items? and item.role?
        item.element = <RoleGuard role={item.role}/>
      children = if item.items? then processRoutes item.items
      return
        path: item.path
        element:
          if (not item.role?) or useCurrentUserIsInRole item.role
            item.element
          else
            <AccessDeniedPage/>
        children: children
  routes = processRoutes _.cloneDeep [sourceArray..., defaultRoutes...]
  useRoutes routes


BreadCrumbTemplate = (item, options) ->
  <><span className={item.icon ? ''}/>  <span>{item.label}</span></>


BreadCrumbForPath = ({sourceArray}) ->
  location = useLocation()
  routes = [sourceArray..., defaultRoutes...]
  breadCrumbs =
    location.pathname
    .split('/')[1..]
    .reduce (prev, curr) ->
      [prev..., (routes.find (route) -> route.path is "/#{curr}" or route.path is curr) ? (prev[-1..][0]?.items?.find (route) -> route.path is curr)]
    , []
    .filter (item) -> item?
    .map (item) -> {item..., template: BreadCrumbTemplate}

  <BreadCrumb model={breadCrumbs}/>


export SdAppLayout = ({dataOptions}) ->
  {sourceName, sourceArray, toolbarStart, routerLess} = dataOptions

  [sidebarIsVisible, setSidebarIsVisible] = useState false

  belowToolbarStyle =
    if isMobile
      display: 'block'
    else
      display: 'grid'
      gridTemplateColumns: 'auto 1fr'
      justifyItems: 'stretch'
      gridGap: '5px'


  layoutBody =
    <div className="h-screen w-screen p-1 surface-ground #{if isMobile then 'mobile-app' else ''}" style={
      display: 'grid'
      gridTemplateRows: 'auto 1fr'
      justifyItems: 'stretch'
      gridGap: '5px'
    }>
      <AppToolbar
        isMobile={isMobile}
        toolbarStart={toolbarStart}
        onToggleSidebar={-> setSidebarIsVisible (x) -> not x}
      />

      <div className="surface-ground" style={belowToolbarStyle}>

        <MainMenu
          sourceArray={sourceArray}
          sidebarIsVisible={sidebarIsVisible}
          onCloseSidebar={-> setSidebarIsVisible false}
        />

        <div className="h-full" style={display: 'grid', gridTemplateRows: 'auto 1fr', gridGap: '5px'}>
          <BreadCrumbForPath sourceArray={sourceArray}/>
          <MainRoutes sourceArray={sourceArray}/>
        </div>
        
      </div>
    </div>

  if routerLess
    layoutBody
  else
    <Router>
      {layoutBody}
    </Router>
