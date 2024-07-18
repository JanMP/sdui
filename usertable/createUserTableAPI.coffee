import {Meteor} from 'meteor/meteor'
import {Accounts} from 'meteor/accounts-base'
import {SimpleSchema} from 'meteor/janmp:sdui'
import {createTableDataAPI} from '../api/createTableDataAPI.coffee'
import {currentUserMustBeInRole} from '../common/roleChecks.coffee'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {Roles} from 'meteor/alanning:roles'
import {RoleSelect} from './RoleSelect.coffee'
import _ from 'lodash'
import {runTransaction} from '../common/runTransaction.coffee'

###*
 * createUserTableAPI function configures and exposes an API for user table manipulation, including CRUD operations,
 * roles assignment, and user status tracking. It leverages Meteorjs, MongoDB, and SimpleSchema for data validation.
 *
 * @param {Object} options - Configuration options for the user table API.
 * @param {SimpleSchema} options.userProfileSchema - Schema for user profile information.
 * @param {Function} options.getAllowedRoles - Function returning a list of allowed roles for users.
 * @param {String} options.viewUserTableRole - Role required to view the user table. Defaults to 'admin'.
 * @param {String} options.editUserRole - Role required to edit users. Defaults to 'admin'.
  ###
export createUserTableAPI = ({userProfileSchema, getAllowedRoles, viewUserTableRole = 'admin'  , editUserRole = 'admin'}) ->

  getAllowedRoles ?= ->
    global: ['admin', 'registered- user']
  
  defaultUserProfileSchema = new SimpleSchema
    firstName:
      type: String
      optional: true
    lastName:
      type: String
      optional: true

  userStatusSchema = new SimpleSchema
    lastlogin:
      type: Object
      optional: true
    'lastlogin.date':
      type: Date
      optional: true
    'lastlogin.ipAddr':
      type: String
      optional:true
    userAgent:
      type: String
      optional: true
    lastActivity:
      type: Date
      optional: true
    online:
      type: Boolean
      optional: true

  userSchema = new SimpleSchema
    _id:
      type: String
      optional: true
    username:
      type: String
      optional: true
    emails:
      type: Array
      optional: true
    "emails.$":
      type: Object
    "emails.$.address":
      type: String
      regEx: SimpleSchema.RegEx.Email
    "emails.$.verified":
      type: Boolean
    registered_emails:
      type: Array
      optional: true
    'registered_emails.$':
      type: Object
      blackbox: true
    createdAt:
      type: Date
    profile:
      type: userProfileSchema ? defaultUserProfileSchema
      optional: true
    status:
      type: userStatusSchema
      optional: true
    services:
      type: Object
      optional: true
      blackbox: true
    roles:
      type: Array
      optional: true
    'roles.$':
      type: Object
      blackbox: true
    heartbeat:
      type: Date
      optional: true

  userListSchema = new SimpleSchema
    email:
      type: String
    username:
      type: String
    verified:
      type: Boolean
    online:
      type: Boolean
    roles:
      type: Array
      sdTable:
        component: RoleSelect
        overflow: true
    'roles.$':
      type: String

  getPreSelectPipeline = -> [
    $match:
      'emails.0': $exists: true
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
      new SimpleSchema
        id: String
        value:
          type: Array
          optional: true
        'value.$':
          type: Object
          blackbox: true
      .validator()
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

      for {email, username, password, roles} in Meteor.settings.seedUsers ? []
        unless (await Meteor.users.findOneAsync('emails.0.address': email))?
          if (id = await Accounts.createUserAsync {email, username, password})?
            unless (await Meteor.roleAssignment.findOneAsync 'user._id': id)?
              Roles.addUsersToRolesAsync id, roles

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
    canEdit: false
    canAdd: false
    canDelete: true
    canExport: true
    getObservers: -> [Meteor.roleAssignment.find()]

