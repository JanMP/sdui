import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {createTableDataAPI} from '../api/createTableDataAPI'
import {currentUserMustBeInRole} from '../common/roleChecks'
import SimpleSchema from 'meteor/aldeed:simple-schema'
import pick from 'lodash/pick'
import {meteorApply} from '../common/meteorApply'

sourceSchemaDefinition =
  title:
    type: String
    optional: true
  userIds:
    type: Array
    optional: true
  'userIds.$':
    type: String
  createdAt:
    type: Date
    optional: true

additionalListFieldsSchemaDefinition =
  users:
    type: Array
    optional: true
  'users.$':
    type: Object
    blackbox: true

sourceSchema = new SimpleSchema sourceSchemaDefinition

listSchema =
  new SimpleSchema {sourceSchemaDefinition..., additionalListFieldsSchemaDefinition...}

formSchema = new SimpleSchema pick sourceSchemaDefinition, ['title']

###*
  @description
    setup a SdList for the chat sessions (to be displayed on the left hand side of the chat)
  @param {Object} options
  @param {String} options.sourceName
  @param {Mongo.Collection} options.sessionListCollection
  @param {String} options.viewChatRole
  @param {String} options.addSessionRole
  ###
export createChatSessionListAPI = ({sourceName, sessionListCollection, viewChatRole, addSessionRole}) ->
  
  getPreSelectPipeline = -> [
    $match:
      userIds: Meteor.userId()
  ]

  getSessionListProcessorPipeline = -> [
    $unwind: '$userIds'
  ,
    $lookup:
      from: 'users'
      localField: 'userIds'
      foreignField: '_id'
      as: 'user'
  ,
    $addFields:
      username: $arrayElemAt: ['$user.username', 0]
      email: $arrayElemAt: ['$user.emails.address', 0]
      userId: $arrayElemAt: ['$user._id', 0]
  ,
    $unset: 'user'
  ,
    $group:
      _id: '$_id'
      title: $first: '$title'
      createdAt: $first: '$createdAt'
      userIds: $push: '$userIds'
      users: $push:
        username: '$username'
        email: $arrayElemAt: ['$email', 0]
        userId: '$userId'
  ]


  createTableDataAPI
    sourceName: "#{sourceName}.sessions"
    collection: sessionListCollection
    sourceSchema: sourceSchema
    listSchema: listSchema
    formSchema: formSchema
    viewTableRole: viewChatRole
    canAdd: true
    canDelete: true
    canEdit: false
    canSort: true
    initialSortColumn: 'createdAt'
    initialSortDirection: 'DESC'

    getPreSelectPipeline: getPreSelectPipeline
    getProcessorPipeline: getSessionListProcessorPipeline