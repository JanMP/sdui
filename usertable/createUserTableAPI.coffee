import {Meteor} from 'meteor/meteor'
import {Accounts} from 'meteor/accounts-base'
import SimpleSchema from 'simpl-schema'
import {createTableDataAPI} from '../api/createTableDataAPI.coffee'
import {currentUserMustBeInRole} from '../common/roleChecks.coffee'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {Roles} from 'meteor/alanning:roles'
import {RoleSelect} from './RoleSelect'
import _ from 'lodash'

SimpleSchema.extendOptions(['sdTable', 'uniforms'])

export createUserTableAPI = ({userProfileSchema, getAllowedRoles, viewUserTableRole = 'admin'  , editUserRole = 'admin'}) ->

  getAllowedRoles ?= ->
    global: ['admin', 'editor']
  
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
      verified: '$email.verified'
      online: '$status.online'
      roles: 1
  ]

  createRoles = ->
    if Meteor.isServer
      allowedRoles = getAllowedRoles()
      allowedRoles.global.forEach (role) ->
        Roles.createRole role, unlessExists: true
      if allowedRoles.scope?
        _(allowedRoles.scope).keys().forEach (scope) ->
          allowedRoles.scope[scope].forEach (role) ->
            Roles.createRole role, unlessExists: true

  seedUsers = ->
    if Meteor.isServer
      Meteor.settings.seedUsers?.forEach ({email, username, password, roles}) ->
        unless (await Meteor.users.findOneAsync('emails.0.address': email))?
          if (id = Accounts.createUser {email, username, password})?
            unless (await Meteor.roleAssignment.findOneAsync 'user._id': id)?
              Roles.addUsersToRoles id, roles

  createRoles()
  seedUsers()

  new ValidatedMethod
    name: 'user.getAllowedRoles'
    validate: ->
    run: ->
      if Meteor.isServer then getAllowedRoles()


  new ValidatedMethod
    name: 'user.createRoles'
    validate: ->
    run: createRoles


  new ValidatedMethod
    name: 'user.onChangeRoles'
    validate:
      new SimpleSchema
        id: String
        value:
          type: Array
        'value.$':
          type: Object
          blackbox: true
      .validator()
    run: ({id, value}) ->
      currentUserMustBeInRole editUserRole
      scopesForUser = Roles.getGroupsForUser id
      scopesForValue = _(value).map('scope').uniq().value()
      if Meteor.isServer
        _(scopesForUser).difference(scopesForValue).forEach (scope) ->
          Roles.setUserRoles id, [], scope
        _(value).groupBy('scope').forEach (rolesForScope, scope) ->
          Roles.setUserRoles id, _(rolesForScope).map('role').value(), if scope is 'null' then null else scope


  if Meteor.isServer
    Meteor.publish null, ->
      if @userId
        Meteor.roleAssignment.find 'user._id': @userId
      else
        @ready()


  #returning the dataOptions
  createTableDataAPI
    viewTableRole: viewUserTableRole
    editRole: editUserRole
    deleteRole: editUserRole
    sourceName: 'users'
    sourceSchema: userSchema
    listSchema: userListSchema
    collection: Meteor.users
    getProcessorPipeline: getProcessorPipeline
    canSearch: true
    canEdit: false
    canAdd: false
    canDelete: true
    canExport: true
    observers: [Meteor.roleAssignment.find()]