import {Meteor} from 'meteor/meteor'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import SimpleSchema from 'simpl-schema'
import {currentUserMustBeInRole, userMustBeInRole} from '../common/roleChecks.coffee'
import {Accounts} from 'meteor/accounts-base'
import {Roles} from 'meteor/alanning:roles'
import {Random} from 'meteor/random'
import {WebApp} from 'meteor/webapp'


export createUserManagementAPI = ({sourceName, path, userRole, adminRole, apiKey}) ->

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
      id = Accounts.createUser {username, password}
      Roles.addUsersToRoles id, userRole.role, userRole.scope
      res.writeHead 200
      res.end JSON.stringify {username, password}
    catch error
      res.writeHead 500
      res.end error.message

  # WebApp.connectHandlers.use "#{path}/remove", (req, res, next) ->
  #   return unless checkAuth req, res
  #   [username] = req.url.split('/').splice(1)
  #   try
  #     user = Meteor.users.findOne {username}
  #     Roles.removeUsersFromRoles user._id, userRole.role, userRole.scope
  #     result = Meteor.users.remove user._id
  #     res.writeHead 200
  #     res.end JSON.stringify result
  #   catch error
  #     res.writeHead 500
  #     res.end error.message


  new ValidatedMethod
    name: "#{sourceName}.addUser"
    validate:
      new SimpleSchema
        username:
          type: String
        password:
          type: String
          optional: true
      .validator()
    run: ({username, password}) ->
      currentUserMustBeInRole adminRole
      return unless Meteor.isServer
      password ?= Random.secret()
      id = Accounts.createUser
        username: username
        password: password
      Roles.addUsersToRoles id, userRole.role, userRole.scope
      {id, username, password}

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
  #     userMustBeInRole user, userRole
  #     unless user
  #       throw new Meteor.Error 'user-not-found', "user #{username} not found"
  #     Roles .removeUsersFromRoles user._id, userRole.role, userRole.scope
  #     Meteor.users.remove user._id