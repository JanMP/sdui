import {Meteor} from 'meteor/meteor'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {Schema} from 'meteor/janmp:sdui'
import {userWithIdIsInRole} from '../common/roleChecks.coffee'
import {Accounts} from 'meteor/accounts-base'
import {Roles} from 'meteor/alanning:roles'
import {Random} from 'meteor/random'
import {WebApp} from 'meteor/webapp'

###@
  # createUserManagementAPI function configures and exposes an API for user management, including user creation and deletion.
  # It leverages Meteorjs, MongoDB, and Schema for data validation.
  #
  # @param {Object} options - Configuration options for the user management API.
  # @param {String} options.sourceName - The name of the source for the user management API.
  # @param {String} options.path - The path for the user management API. Defaults to '/api/users'.
  # @param {String} options.apiKey - The API key for the user management API.
  # @param {String} options.roleScope - The role scope for the user management API.
  # @param {String} options.adminRole - The role (with scope roleScope) required to manage users. Defaults to 'admin'.
  # @param {String} options.initialUserRole - The initial role (with scope RoleScope) for new users. Defaults to 'user'.
  # @param {Array} options.switchableRoles - The roles (with scope roleScope) that can be switched by users. Defaults to [].
  ###
export createUserManagementAPI = ({sourceName, path, apiKey, roleScope, adminRole, initialUserRole, switchableRoles}) ->

  # a simple rest api to add and remove users
  unless apiKey?
    console.warn "no apiKey given for userManagementAPI at #{path}"
  
  path ?= '/api/users'

  checkAuth = (req, res) ->
    return true unless apiKey?
    unless req.headers['x-api-key'] is apiKey
      res.writeHead 401
      res.end 'unauthorized'
      return false
    true

  WebApp.handlers.use "#{path}/add/:username", (req, res, next) ->
    return unless checkAuth req, res
    username = req.params.username
    password = Random.secret()
    try
      id = await Accounts.createUserAsync {username, password}
      await Roles.addUsersToRolesAsync id, initialUserRole, roleScope
      res
        .send {username, password, id}
        .status 200
        .end()
    catch error
      res
        .status 500
        .send error.message
        .end()

  WebApp.handlers.use "#{path}/remove/:username", (req, res, next) ->
    return unless checkAuth req, res
    try
      username = req.params.username
      unless (user = await Meteor.users.findOneAsync {username})?
        throw new Error "user with username '#{username}' not found"
      unless await userWithIdIsInRole : id: user._id, role: {role: switchableRoles, scope: roleScope}
        throw new Error "user #{username} not in roles #{JSON.stringify switchableRoles} in scope: #{roleScope}"
      currentRoles = await Roles.getRolesForUserAsync user._id, scope: roleScope
      await Roles.removeUsersFromRolesAsync user._id, currentRoles, roleScope
      result = await Meteor.users.removeAsync user._id
      if result isnt 1
        throw new Error "user #{username} not removed"
      res
        .send deletedUsers: result
        .status 200
        .end()
    catch error
      console.error error
      res
        .status 500
        .send error.message
        .end()

  WebApp.handlers.use "#{path}/role/:username/:role", (req, res, next) ->
    return unless checkAuth req, res
    try
      {username, role} = req.params
      unless switchableRoles.includes role
        throw new Error "role #{role} not in #{JSON.stringify switchableRoles}"
      user = await Meteor.users.findOneAsync {username}
      unless await userWithIdIsInRole : id: user._id, role: {role: switchableRoles, scope: roleScope}
        throw new Error "user #{username} not in roles #{JSON.stringify switchableRoles} in scope: #{roleScope}"
      await Roles.setUserRolesAsync user._id, role, roleScope
      res
        .status 200
        .send {username, role}
        .end()
    catch error
      res
        .status 500
        .send error.message
        .end()
  
  WebApp.handlers.use "#{path}/roles/:username", (req, res, next) ->
    return unless checkAuth req, res
    try
      username = req.params.username
      user = await Meteor.users.findOneAsync {username}
      {createdAt} = user
      roles = await Roles.getRolesForUserAsync user._id, scope: roleScope
      res
        .status 200
        .send {username, roles, createdAt}
        .end()
    catch error
      res
        .status 500
        .send error.message
        .end()