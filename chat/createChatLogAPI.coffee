import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import SimpleSchema from 'simpl-schema'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {createTableDataAPI, chatSchema} from 'meteor/janmp:sdui'
import _ from 'lodash'

SimpleSchema.extendOptions(['sdTable', 'uniforms'])

# Add a mongo collection with tokencosts, so we can use it in the pipeline
TokenCosts = new Mongo.Collection 'tokenCosts'

if Meteor.isServer
  do ->
    tokenCosts =
      'gpt-4-1106-preview':
        prompt: 0.00001
        completion: 0.00003
      'gpt-3.5-turbo-1106':
        prompt: 0.000001
        completion: 0.000002
      'gpt-4':
        prompt: 0.00003
        completion: 0.00006
      'mistral-small':
        prompt: 0.0000006
        completion: 0.0000018
      'mistral-medium':
        prompt: 0.0000025
        completion: 0.0000075

    await TokenCosts.removeAsync {}
    for model, usage of tokenCosts
      await TokenCosts.insertAsync
        model: model
        prompt: usage.prompt
        completion: usage.completion


export addCostsPipeline = [
  $lookup:
    from: 'tokenCosts'
    localField: 'usage.model'
    foreignField: 'model'
    as: 'costsForModel'
,
  $addFields:
    costsForModel: $arrayElemAt: ['$costsForModel', 0]
,
  $fill:
    output:
      usage: value:
        prompt: 0
        completion: 0
      costsForModel: value:
        prompt: 0
        completion: 0
,
  $addFields:
    costInUSD:
      $sum:
        $add: [
          $multiply: ['$usage.prompt', '$costsForModel.prompt']
        ,
          $multiply: ['$usage.completion', '$costsForModel.completion']
        ]
]

listSchemaDefinition =
  sessionId: String
  userName: String
  createdAt:
    type: Date
    label: 'Letzte Aktivität'
  models:
    type: Array
    label: 'LLMs'
  'models.$': String
  promptTokens: SimpleSchema.Integer
  completionTokens: SimpleSchema.Integer
  costInUSD:
    type: Number
    label: 'Kosten in USD'
  hasThumbsDown:
    type: Boolean
    label: 'Daumen runter'

listSchema = new SimpleSchema listSchemaDefinition


getAddSessionPipeline = ({sourceName}) -> [
  $lookup:
    from: "#{sourceName}.sessions"
    localField: 'sessionId'
    foreignField: '_id'
    as: 'session'
,
  $addFields:
    session: $arrayElemAt: ['$session', 0]
]

summaryPipeline = [
  $sort:
    createdAt: 1
,
  $group:
    _id: '$sessionId'
    sessionId: $first: '$sessionId'
    userId: $first: $arrayElemAt: ['$session.userIds', 0]
    createdAt: $last: '$createdAt'
    models: $addToSet: '$usage.model'
    promptTokens: $sum: '$usage.prompt'
    completionTokens: $sum: '$usage.completion'
    costInUSD: $sum: '$costInUSD'
    thumbs: $addToSet: '$feedback.thumbs'
,
  $addFields:
    costInUSD: $round: ['$costInUSD', 3]
    hasThumbsDown: $in: ['down', '$thumbs']
]

addUsernamePipeline = [
  $lookup:
    from: 'users'
    localField: 'userId'
    foreignField: '_id'
    as: 'user'
,
  $addFields:
    userName: $arrayElemAt: ['$user.username', 0]
,
  $project:
    user: 0
]

getProcessorPipeline = ({sourceName}) -> [
  addCostsPipeline...
  (getAddSessionPipeline {sourceName})...
  summaryPipeline...
  addUsernamePipeline...
]

getMessagesForSessionPipeline = ({sourceName, sessionId}) -> [
  $match:
    sessionId: sessionId
,
  addCostsPipeline...
  (getAddSessionPipeline {sourceName})...
,
  $addFields:
    costInUSD: $round: ['$costInUSD', 3]
, $sort:
    createdAt: 1
]

###@
  @param {Object} options
  @param {String} options.sourceName - the sourceName of the chat
  @param {String} options.messageCollection
  @param {Object} options.viewTableRole - default: {scope: 'dev', role: 'user'}
  @returns {Object} dataOptions
  ###
export createChatLogAPI = ({sourceName, messageCollection, viewTableRole}) ->
  
  logSourceName = "#{sourceName}.Log"
  viewTableRole ?= scope: 'dev', role: 'user'
  
  dataOptions = createTableDataAPI
    sourceName: logSourceName
    sourceSchema: chatSchema
    collection: messageCollection
    listSchema: listSchema
    viewTableRole: viewTableRole
    canEdit: false
    showRowCount: true
    getProcessorPipeline: getProcessorPipeline
    canExport: true
    canUseQueryEditor: false
    initialSortColumn: 'createdAt'
    initialSortDirection: 'DESC'
    noAutomaticObserver: true
    ovservers: [
      messageCollection.find
        $or: [
          workInProgress: $exists: false
        , workInProgress: false
        ]
    ]
    debounceDelay: 10000

  new ValidatedMethod
    name: "#{logSourceName}.getMessagesForSession"
    validate: new SimpleSchema
      sessionId: String
    .validator()
    run: ({sessionId}) ->
      return unless Meteor.isServer
      messageCollection
      .rawCollection()
      .aggregate getMessagesForSessionPipeline {sourceName, sessionId}
      .toArray()

  dataOptions