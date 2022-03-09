import {Meteor} from 'meteor/meteor'
import {Accounts} from 'meteor/accounts-base'
import SimpleSchema from 'simpl-schema'
import {createTableDataAPI} from '../api/createTableDataAPI.coffee'
import {currentUserMustBeInRole} from '../common/roleChecks.coffee'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {Roles} from 'meteor/alanning:roles'
import {RoleSelect} from './RoleSelect'


export createUserTableAPI = ({userProfileSchema, allowedRoles}) ->

  allowedRoles ?= ['admin', 'editor']
  
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
        component: RoleSelect {allowedRoles}
        overflow: true
    'roles.$':
      type: String

  getProcessorPipeline = -> [
    $lookup:
      from: 'role-assignment'
      localField: '_id'
      foreignField: 'user._id'
      as: 'roleobject'
  ,
    $addFields:
      roles: '$roleobject.role._id'
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

  allowedRoles.forEach (role) ->
    Roles.createRole role, unlessExists: true

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
        change:
          type: Object
          blackbox: true
      .validator()
    run: ({id, value, change}) ->
      currentUserMustBeInRole 'logged-in'
      if Meteor.isServer
        roles = value.map (v) -> v.value
        switch change.action
          when 'remove-value'
            console.log "remove role #{change.removedValue.value} from user #{id}"
          when 'select-option'
            console.log "set role #{change.option.value} for user #{id}"
          when 'clear'
            console.log "remove roles #{change.removedValues.map (v) -> v.value} from user #{id}"
          else
            throw new Meteor.Error 'unknown change action'
        Roles.setUserRoles id, roles

  if Meteor.isServer
    Meteor.publish null, ->
      if @userId
        Meteor.roleAssignment.find 'user._id': @userId
      else
        @ready()

  #returning the dataOptions
  createTableDataAPI
    viewTableRole: 'logged-in'
    editRole: 'logged-in'
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