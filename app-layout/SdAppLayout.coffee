import {Meteor} from 'meteor/meteor'
import {BrowserRouter as Router, Routes, Route, useLocation, useNavigate} from 'react-router-dom'
import React from 'react'
import {Menu} from 'primereact/menu'
import {BreadCrumb} from 'primereact/breadcrumb'
import {AppToolbar} from './AppToolbar.coffee'
import _ from 'lodash'

MainMenu = ({sourceArray}) ->
  navigate = useNavigate({sourceArray})
  classNameForPath = (path) ->
    if location.pathname is path
      'border-primary-500 border-1'
    else
      ''
  processMenuItems = (items, parentPath) ->
    _(items).map (item) ->
      if item.items
        item.items = processMenuItems item.items, item.path
      if item.path
        if parentPath
          item.path = parentPath + '/' + item.path
        item.command = -> navigate item.path
        item.className = classNameForPath item.path
      item
    .value()

  menuItems = processMenuItems _.cloneDeep sourceArray
  
  <Menu multiple model={menuItems} className="h-full"/>


MainRoutes = ({sourceArray}) ->
  processRoutes = (items) ->
    _(items).map (item) ->
      children = if item.items? then processRoutes item.items
      <Route path={item.path} children={children} element={item.element}/>
  routes = processRoutes _.cloneDeep sourceArray
  <Routes children={routes}/>

BreadCrumbForPath = ->
  location = useLocation()
  breadCrumbs = _.map location.pathname.split('/'), (path) ->
    if path is ''
      {label: 'Home', icon: 'pi pi-fw pi-home', path: '/'}
    else
      {label: path, path: path}
  # <pre>{JSON.stringify locbreaation, null, 2}</pre>

  <BreadCrumb model={breadCrumbs}/>

export SdAppLayout = ({dataOptions, toolbarStart}) ->
  {sourceName, sourceArray} = dataOptions

  <Router>
    <div className="h-screen w-screen flex flex-column bg-gray-500">
      <AppToolbar toolbarStart={toolbarStart ? -> null}/>

      <div className="flex-grow-1 grid p-2">
        <div className="col-fixed">
          <MainMenu sourceArray={sourceArray}/>
        </div>
        <div className="col">
          <BreadCrumbForPath/>
          <MainRoutes sourceArray={sourceArray}/>
        </div>
      </div>
    </div>
  </Router>