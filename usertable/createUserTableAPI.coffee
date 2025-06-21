import {Meteor} from 'meteor/meteor'
import {Accounts} from 'meteor/accounts-base'
import {Schema} from 'meteor/janmp:sdui'
import {createTableDataAPI} from '../api/createTableDataAPI.coffee'
import {currentUserMustBeInRole} from '../common/roleChecks.coffee'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {Roles} from 'meteor/alanning:roles'
import {RolesDisplay} from './RolesDisplay.coffee'
import {RoleSelectField} from './RoleSelect.coffee'
import _ from 'lodash'
import {runTransaction} from '../common/runTransaction.coffee'

###*
 * createUserTableAPI function configures and exposes an API for user table manipulation, including CRUD operations,
 * roles assignment, and user status tracking. It leverages Meteorjs, MongoDB, and Schema for data validation.
 *
 * @param {Object} options - Configuration options for the user table API.
 * @param {Schema} options.userProfileSchema - Schema for user profile information.
 * @param {Function} options.getAllowedRoles - Function returning a list of allowed roles for users.
 * @param {String} options.viewUserTableRole - Role required to view the user table. Defaults to 'admin'.
 * @param {String} options.editUserRole - Role required to edit users. Defaults to 'admin'.
  ###
export createUserTableAPI = ({userProfileSchema, getAllowedRoles, viewUserTableRole = 'admin'  , editUserRole = 'admin'}) ->

  getAllowedRoles ?= ->
    global: ['admin', 'user']

  defaultUserProfileSchema =
    type: 'object'
    properties:
      firstName:
        type: 'string'
      lastName:
        type: 'string'

  userStatusSchema =
    type: 'object'
    properties:
      lastlogin:
        type: 'object'
        properties:
          date: instanceof: 'Date'
          ipAddr: type: 'string'
      userAgent:
        type: 'string'
      lastActivity: instanceof: 'Date'
      online: type: 'boolean'

  userSchema = new Schema
    type: 'object'
    properties:
      _id: type: 'string'
      username: type: 'string'
      emails:
        type: 'array'
        items:
          type: 'object'
          properties:
            address: type: 'string'
            verified: type: 'boolean'
      registered_emails:
        type: 'array'
        items:
          type: 'object'
          properties:
            address: type: 'string'
            verified: type: 'boolean'
      createdAt: instanceof: 'Date'
      profile: userProfileSchema ? defaultUserProfileSchema
      status: userStatusSchema
      services: type: 'object'
      roles:
        type: 'array'
        items: type: 'object'
      heartbeat: instanceof: 'Date'


  userListSchema = new Schema
    type: 'object'
    properties:
      email:
        type: 'string'
        uniforms: disabled: true
      username:
        type: 'string'
        uniforms: disabled: true
      verified:
        type: 'boolean'
        uniforms: disabled: true
      online:
        type: 'boolean'
        uniforms: disabled: true
      roles:
        type: 'array'
        items: type: 'object'
        sdTable:
          component: RolesDisplay
        uniforms:
          component: RoleSelectField
        #   overflow: true

  getPreSelectPipeline = -> [
    $match:
      'emails.0.address': $exists: true
  ]

  getProcessorPipeline = -> [
    $lookup:
      from: 'role-assignment'
      localField: '_id'
      foreignField: 'user._id'
      as: 'roles'
  ,
    $addFields:
      email: $arrayElemAt: ['$emails', 0]
  ,
    $project:
      _id: 1
      email: '$email.address'
      username: 1
      verified: '$email.verified'
      online: '$status.online'
      roles: 1
  ]

  makeSubmitMehodRunFkt = ({collection, transformIdToMongo, transformIdToMiniMongo}) ->
    ({id, data}) ->
      {roles} = data
      id = transformIdToMongo id
      currentUserMustBeInRole editUserRole
      if Meteor.isServer
        scopesForUser = await Roles.getScopesForUserAsync id
        scopesForValue = _(roles).map('scope').uniq().value()
        runTransaction ->
          # remove all roles for scopes that are not in the new value
          for scope in _(scopesForUser).difference(scopesForValue).value()
            await Roles.setUserRolesAsync id, [], scope
          # remove all roles for the global scope if global scope is not in the new value
          if roles.filter((role) -> not role.scope?).length is 0
            await Roles.setUserRolesAsync id, []
          # set roles for all scopes in the new value
          await Promise.all(
            _(roles).groupBy('scope').map (rolesForScope, scope) ->
              Roles.setUserRolesAsync id, _(rolesForScope).map('role').value(), if scope is 'null' then null else scope
            .value()
          )
  new ValidatedMethod
    name: 'user.getAllowedRoles'
    validate: ->
    run: ->
      if Meteor.isServer then getAllowedRoles()

  new ValidatedMethod
    name: 'user.test'
    validate: null
    run: ->
      console.log 'user.test'

  new ValidatedMethod
    name: 'user.onChangeRoles'
    validate:
      new Schema
        type: 'object'
        properties:
          id: type: 'string'
          value:
            type: 'array'
            items:
              type: 'object'
        required: ['id', 'value']
      .methodValidator
    run: ({id, value}) ->
      currentUserMustBeInRole editUserRole
      if Meteor.isServer
        scopesForUser = await Roles.getScopesForUserAsync id
        scopesForValue = _(value).map('scope').uniq().value()
        runTransaction ->
          # remove all roles for scopes that are not in the new value
          for scope in _(scopesForUser).difference(scopesForValue).value()
            await Roles.setUserRolesAsync id, [], scope
          # remove all roles for the global scope if global scope is not in the new value
          if value.filter((role) -> not role.scope?).length is 0
            await Roles.setUserRolesAsync id, []
          # set roles for all scopes in the new value
          await Promise.all(
            _(value).groupBy('scope').map (rolesForScope, scope) ->
              Roles.setUserRolesAsync id, _(rolesForScope).map('role').value(), if scope is 'null' then null else scope
            .value()
          )

  new ValidatedMethod
    name: 'users.getAllowedRoles'
    validate: null
    run: ->
      return unless Meteor.isServer
      getAllowedRoles()

  if Meteor.isServer
    do ->
      console.log 'seeding allowed roles and users'
      allowedRoles = await getAllowedRoles()
      for role in allowedRoles.global
        await Roles.createRoleAsync role, unlessExists: true
      if allowedRoles.scope?
        for scope in _(allowedRoles.scope).keys().value()
          for role in allowedRoles.scope[scope]
            await Roles.createRoleAsync role, unlessExists: true

      for {email, username, password, roles} in Meteor.settings?.seedUsers ? []
        unless (await Meteor.users.findOneAsync('emails.0.address': email))?
          try
            console.log "creating user", {email, username, password, roles}
            if (id = await Accounts.createUserAsync {email, username, password})?
              unless (await Meteor.roleAssignment.findOneAsync 'user._id': id)?
                Roles.addUsersToRolesAsync id, roles
          catch error
            console.log error

  if Meteor.isServer
    Meteor.publish null, ->
      if @userId
        Meteor.roleAssignment.find 'user._id': @userId
      else
        return @ready()


  #returning the dataOptions
  createTableDataAPI
    viewTableRole: viewUserTableRole
    editRole: editUserRole
    deleteRole: editUserRole
    sourceName: 'users'
    sourceSchema: userSchema
    listSchema: userListSchema
    collection: Meteor.users
    getPreSelectPipeline: getPreSelectPipeline
    getProcessorPipeline: getProcessorPipeline
    canSearch: true
    canEdit: true
    canAdd: false
    canDelete: true
    canExport: true
    makeSubmitMethodRunFkt: makeSubmitMehodRunFkt

