import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {createTableDataAPI} from '../api/createTableDataAPI'
import {currentUserMustBeInRole} from '../common/roleChecks'
import {Schema} from 'meteor/janmp:sdui'
import pick from 'lodash/pick'
import {meteorApply} from '../common/meteorApply'


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
  sourceSchema = new Schema
    type: 'object'
    properties:
      title:
        type: 'string'
      userIds:
        type: 'array'
        items: type: 'string'
      createdAt:
        type: 'object'
        instanceof: 'Date'
      threadId:
        type: 'string'
      model:
        type: 'string'
        enum: [
          "anthropic/claude-3-5-haiku-latest",
          "anthropic/claude-sonnet-4-20250514",
          "google_genai/gemini-2.5-flash",
          "mistralai/mistral-small-latest",
          # "mistralai/magistral-medium-2506",
          "openai/gpt-4.1",
        ]
    required: ['title', 'model']

  listSchema =
    sourceSchema.addProperty
      users:
        type: 'array'
        items: type: 'object'

  formSchema = sourceSchema.pick ['title', 'model']

  getPreSelectPipeline = ({pub}) ->
    [
      $match:
        $or: [
          archived: $exists: false
        ,
          archived: false
        ]
        userIds: pub?.userId ? Meteor.userId()
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
      model: $first: '$model'
      createdAt: $first: '$createdAt'
      userIds: $push: '$userIds'
      users: $push:
        username: '$username'
        email: $arrayElemAt: ['$email', 0]
        userId: '$userId'
      threadId: $first: '$threadId'
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
    usePubSub: true
    initialSortColumn: 'createdAt'
    initialSortDirection: 'DESC'
    getPreSelectPipeline: getPreSelectPipeline
    getProcessorPipeline: getSessionListProcessorPipeline