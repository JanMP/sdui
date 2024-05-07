import {Meteor} from 'meteor/meteor'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import SimpleSchema from 'meteor/aldeed:simple-schema'
import {currentUserMustBeInRole, userWithIdIsInRole} from '../common/roleChecks.coffee'
import {Accounts} from 'meteor/accounts-base'
import {Roles} from 'meteor/alanning:roles'
import {Random} from 'meteor/random'
import {WebApp} from 'meteor/webapp'

###@
  # createUserManagementAPI function configures and exposes an API for user management, including user creation and deletion.
  # It leverages Meteorjs, MongoDB, and SimpleSchema for data validation.
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

  WebApp.connectHandlers.use "#{path}/add", (req, res, next) ->
    return unless checkAuth req, res
    [username] = req.url.split('/').splice(1)
    password = Random.secret()
    try
      id = await Accounts.createUserAsync {username, password}
      await Roles.addUsersToRolesAsync id, initialUserRole, roleScope
      res.writeHead 200
      res.end JSON.stringify {username, password, id}
    catch error
      res.writeHead 500
      res.end error.message

  WebApp.connectHandlers.use "#{path}/remove", (req, res, next) ->
    return unless checkAuth req, res
    try
      [username] = req.url.split('/').splice(1)
      user = await Meteor.users.findOne {username}
      unless userWithIdIsInRole : id: user._id, role: {role: switchableRoles, scope: roleScope}
        throw new Error "user #{username} not in roles #{JSON.stringify switchableRoles} in scope: #{roleScope}"
      currentRoles = await Roles.getRolesForUserAsync user._id, scope: roleScope
      await Roles.removeUsersFromRolesAsync user._id, currentRoles, roleScope
      result = await Meteor.users.removeAsync user._id
      if result isnt 1
        throw new Error "user #{username} not removed"
      res.writeHead 200
      res.end JSON.stringify deletedUsers: result
    catch error
      res.writeHead 500
      res.end error.message

  WebApp.connectHandlers.use "#{path}/role", (req, res, next) ->
    return unless checkAuth req, res
    try
      [username, role] = req.url.split('/').splice(1)
      unless switchableRoles.includes role
        throw new Error "role #{role} not in #{JSON.stringify switchableRoles}"
      user = await Meteor.users.findOneAsync {username}
      unless userWithIdIsInRole : id: user._id, role: {role: switchableRoles, scope: roleScope}
        throw new Error "user #{username} not in roles #{JSON.stringify switchableRoles} in scope: #{roleScope}"
      await Roles.setUserRolesAsync user._id, role, roleScope
      res.writeHead 200
      res.end JSON.stringify {username, role}
    catch error
      res.writeHead 500
      res.end error.message
  
  WebApp.connectHandlers.use "#{path}/roles", (req, res, next) ->
    return unless checkAuth req, res
    try
      [username] = req.url.split('/').splice(1)
      user = await Meteor.users.findOneAsync {username}
      roles = await Roles.getRolesForUserAsync user._id, scope: roleScope
      res.writeHead 200
      res.end JSON.stringify {username, roles}
    catch error
      res.writeHead 500
      res.end error.message
  

  # new ValidatedMethod
  #   name: "#{sourceName}.addUser"
  #   validate:
  #     new SimpleSchema
  #       username:
  #         type: String
  #       password:
  #         type: String
  #         optional: true
  #     .validator()
  #   run: ({username, password}) ->
  #     currentUserMustBeInRole adminRole
  #     return unless Meteor.isServer
  #     password ?= Random.secret()
  #     id = Accounts.createUser
  #       username: username
  #       password: password
  #     Roles.addUsersToRoles id, userRole.role, userRole.scope
  #     {id, username, password}

  # new ValidatedMethod
  #   name: "#{sourceName}.removeUser"
  #   validate:
  #     new SimpleSchema
  #       username:
  #         type: String
  #     .validator()
  #   run: ({username}) ->
  #     currentUserMustBeInRole adminRole
  #     return unless Meteor.isServer
  #     user = Meteor.users.findOne {username}
  #     unless userWithIdIsInRole : id: user._id, role: {role: switchableRoles, scope: roleScope}
  #       throw new Error "user #{username} not in roles #{JSON.stringify switchableRoles} in scope: #{roleScope}"
  #     unless user
  #       throw new Meteor.Error 'user-not-found', "user #{username} not found"
  #     Roles .removeUsersFromRoles user._id, userRole.role, userRole.scope
  #     Meteor.users.remove user._id