import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {Schema} from '../schema/Schema.coffee'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {createTableDataAPI, chatSchema} from 'meteor/janmp:sdui'
import _ from 'lodash'

# Add a mongo collection with tokencosts, so we can use it in the pipeline
TokenCosts = new Mongo.Collection 'tokenCosts'

if Meteor.isServer
  do ->
    tokenCosts =
      'gpt-4o-mini':
        prompt: .15e-6
        completion: .6e-6
      'gpt-4o':
        prompt: 5e-6
        completion: 15e-6
      'gpt-4-turbo':
        prompt: 10e-6
        completion: 30e-6
      'gpt-3.5-turbo':
        prompt: 3e-6
        completion: 6
      'gpt-4-1106-preview':
        prompt: 1e-5
        completion: 3e-5
      'gpt-4-0125-preview':
        prompt: 1e-5
        completion: 3e-5
      'gpt-3.5-turbo-0125':
        prompt: 5e-7
        completion: 15e-7
      'gpt-3.5-turbo-1106':
        prompt: 1e-6
        completion: 2e-6
      'gpt-4':
        prompt: 30e-6
        completion: 60e-6
      'claude-3-5-sonnet-20240620':
        prompt: 3e-6
        completion: 15e-6
      'claude-3-5-sonnet-20241022':
        prompt: 3e-6
        completion: 15e-6
      'claude-3-5-haiku-20241022':
        prompt: .25e-6
        completion: 1.25e-6
      'mistral-small-2409':
        prompt: .2e-6
        completion: .6e-6
      'open-mistral-nemo-2407':
        prompt: .15e-6
        completion: .15e-6
      'mistral-large-latest':
        prompt: 2e-6
        completion: 6e-6

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

listSchema = new Schema
  type: 'object'
  properties:
    # sessionId: type: 'string'
    userName: type: 'string'
    # models:
    #   type: 'array'
    #   items: type: 'string'
    #   uniforms: label: 'LLMs'
    createdAt:
      type: 'object'
      instanceof: 'Date'
      uniforms: label: 'Letzte Aktivität'
    # promptTokens: type: 'integer'
    # completionTokens: type: 'integer'
    # costInUSD:
    #   type: 'number'
    #   uniforms: label: 'Kosten in USD'
    hasThumbsDown:
      type: 'boolean'
      uniforms: label: 'Daumen runter'


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
    # models: $addToSet: '$usage.model'
    # promptTokens: $sum: '$usage.prompt'
    # completionTokens: $sum: '$usage.completion'
    # costInUSD: $sum: '$costInUSD'
    thumbs: $addToSet: '$feedback.thumbs'
,
  $addFields:
    # costInUSD: $round: ['$costInUSD', 3]
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

getPreSelectPipeline = -> [
    $match:
      $or: [
        chatRole: 'user'
      , feedback: $exists: true
      ]
  ]

getProcessorPipelineForSourceName = ({sourceName}) -> -> [
  # addCostsPipeline...
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
  Sets up the backeend for the chatLogs

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
    getPreSelectPipeline: getPreSelectPipeline
    getProcessorPipeline: getProcessorPipelineForSourceName {sourceName}
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
    usePubSub: false

  new ValidatedMethod
    name: "#{logSourceName}.getMessagesForSession"
    validate:
      new Schema
        type: 'object'
        properties:
          sessionId: type: 'string'
        required: ['sessionId']
      .methodValidator
    run: ({sessionId}) ->
      return unless Meteor.isServer
      messageCollection
      .rawCollection()
      .aggregate getMessagesForSessionPipeline {sourceName, sessionId}
      .toArray()

  selectLastDays = ({forLastDays})  ->
    lastDate =  new Date(new Date().getTime() - forLastDays * 24 * 60 * 60 * 1000)
    $match:
      $expr:
        $gte: ['$createdAt', lastDate]

  statisticsByDay = ({forLastDays})  ->
    [
      selectLastDays {forLastDays}
    ,
      $addFields:
        userMessages: $cond: [ $eq: ['$chatRole', 'user'], 1, 0 ]
        feedbackComment: '$feedback.comment'
    ,
      $group:
        _id: $dateToString: format: '%Y-%m-%d', date: '$createdAt'
        sessionIds: $addToSet: '$sessionId'
        userMessages: $sum: '$userMessages'
        users: $addToSet: '$userId'
        thumbsUp:
          $sum:
            $cond: [ $eq: ['$feedback.thumbs', 'up'], 1, 0 ]
        thumbsDown:
          $sum:
            $cond: [ $eq: ['$feedback.thumbs', 'down'], 1, 0 ]
        feedbackComment:
          $sum:
            $cond: ['$feedbackComment', 1, 0]
    ,
      $addFields:
        sessions: $size: '$sessionIds'
        uniqueUsers: $size: '$users'
        thumbCounts:
          up: '$thumbsUp'
          down: '$thumbsDown'
    ,
      $project:
        sessionIds: 0
        users: 0
        thumbs: 0
        thumbsUp: 0
        thumbsDown: 0
        textFeedback: 0
    ,
      $sort: _id: 1
    ]

  statisticsBySession = ({forLastDays})  ->
    [
      selectLastDays {forLastDays}
    ,
      $addFields:
        userMessages: $cond: [ $eq: ['$chatRole', 'user'], 1, 0 ]
    ,
      $group:
        _id: '$sessionId'
        userMessages: $sum: '$userMessages'
    ,
      $group:
        _id: '$userMessages'
        sessions: $sum: 1
    ,
      $sort: _id: 1
    ]

  statisticTotals = ({forLastDays})  ->
    [
      selectLastDays {forLastDays}
    ,
      $addFields:
        userMessages: $cond: [ $eq: ['$chatRole', 'user'], 1, 0 ]
        feedbackComment: '$feedback.comment'
    ,
      $group:
        _id: null
        userMessages: $sum: '$userMessages'
        users: $addToSet: '$userId'
        thumbsUp:
          $sum:
            $cond: [ $eq: ['$feedback.thumbs', 'up'], 1, 0 ]
        thumbsDown:
          $sum:
            $cond: [ $eq: ['$feedback.thumbs', 'down'], 1, 0 ]
        feedbackComment:
          $sum:
            $cond: ['$feedbackComment', 1, 0]
    ,
      $addFields:
        uniqueUsers: $size: '$users'
        thumbCounts:
          up: '$thumbsUp'
          down: '$thumbsDown'
    ,
      $project:
        users: 0
        thumbs: 0
        thumbsUp: 0
        thumbsDown: 0
        textFeedback: 0
    ]


  new ValidatedMethod
    name: "#{sourceName}.getStatistics"
    validate:
      new Schema
        type: 'object'
        properties:
          forLastDays: type: 'number'
        required: ['forLastDays']
      .methodValidator
    run: ({forLastDays}) ->
      return unless Meteor.isServer
      byDay =
        await messageCollection
          .rawCollection()
          .aggregate statisticsByDay {forLastDays}
          .toArray()
      bySession =
        await messageCollection
          .rawCollection()
          .aggregate statisticsBySession {forLastDays}
          .toArray()
      totals =
        await messageCollection
          .rawCollection()
          .aggregate statisticTotals {forLastDays}
          .toArray()

      {byDay, bySession, totals}

  dataOptions