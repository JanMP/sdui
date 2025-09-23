import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {createChatMethods} from './createChatMethods'
import {createChatPublications} from './createChatPublications'
import {Schema} from '../schema/Schema.coffee'
import {createChatSessionListAPI} from './createChatSessionListAPI'
import {WorkspaceAPI} from '../workspace/WorkspaceAPI.coffee'

export chatSchema = new Schema
  type: 'object'
  properties:
    userId:
      type: 'string'
    sessionId:
      type: 'string'
    createdAt:
      instanceof: 'Date'
    text:
      type: 'string'
    chatRole:
      type: 'string'
      enum: ['user', 'assistant', 'system', 'log']
    usage:
      type: 'object'
      properties:
        model:
          type: 'string'
        prompt:
          type: 'number'
        completion:
          type: 'number'
    workInProgress:
      type: 'boolean'
    feedback:
      type: 'object'
      properties:
        thumbs:
          type: 'string'
          enum: ['up', 'down']
        comment:
          type: 'string'

export chatMetaDataSchema = new Schema
  type: 'object'
  properties:
    sessionId: type: 'string'
    createdAt: instanceof: 'Date'
    data: type: 'object'

###*
  @param {Object} options
  @param {String} options.sourceName
  @param {Mongo.Collection} options.messageCollection
  @param {Mongo.Collection} options.sessionListCollection
  @param {Mongo.Collection} [options.metaDataCollection]
  @param {Mongo.Collection} [options.usageLimitCollection]
  @param {Boolean} [options.isSingleSessionChat]
  @param {Boolean} [options.isDocumentChat=false]
  @param {WorkspaceAPI} [options.workspaceAPI] - if isDocumentChat=true, the connected WorkspaceAPI
  @param {Object} [options.viewChatRole]
  @param {Object} [options.addSessionRole]
  @param {Array} [options.bots]
  @param {Function} [options.reactToNewMessage]
  @param {() => {maxMessagesPerDay?: number, maxSessionsPerDay?: number, maxMessagesPerSession?: number, maxMessageLength?: number} | void} [options.getUsageLimits]
  @param {Function} [options.onNewSession]
  @param {Number} [options.messagesLimit] - max number of messages to be published
  @returns {Object} dataOptions
  ###
export createChatAPI = ({
  sourceName
  messageCollection,
  sessionListCollection
  metaDataCollection
  usageLimitCollection
  isSingleSessionChat
  isDocumentChat = false
  workspaceAPI
  viewChatRole, addSessionRole,
  bots, reactToNewMessage, onNewSession
  messagesLimit = 100
  getUsageLimits = ->
    maxMessageLength: 500,
    maxMessagesPerDay: 1000,
    maxMessagesPerSession: Infinity,
    maxSessionsPerDay: Infinity
}) ->


  # check required props and setup defaults for optional props
  unless sourceName?
    throw new Error 'no sourceName given'

  unless messageCollection?
    throw new Error 'no messageCollection given'

  unless sessionListCollection?
    throw new Error 'no sessionListCollection given'

  if not viewChatRole? and Meteor.isServer
    console.warn "[createChatAPI #{sourceName}]:
      no viewChatRole defined, using 'any' instead."
  viewChatRole ?= 'any'

  if not addSessionRole? and Meteor.isServer
    console.warn "[createChatAPI #{sourceName}]:
      no addSessionRole defined, using '#{viewChatRole}' instead."
  addSessionRole ?= viewChatRole
  bots ?= [] # id, username, email

  if isDocumentChat and not workspaceAPI?
    throw new Error 'isDocumentChat=true requires a connected workspaceAPI'


  sessionListDataOptions =
    createChatSessionListAPI {
      sourceName
      sessionListCollection
      viewChatRole
      addSessionRole
    }

  createChatMethods {
    sourceName
    messageCollection
    sessionListCollection
    metaDataCollection
    isSingleSessionChat
    isDocumentChat
    viewChatRole
    addSessionRole
    reactToNewMessage
    onNewSession
    getUsageLimits
  }

  createChatPublications {
    sourceName
    messageCollection
    sessionListCollection
    metaDataCollection
    isSingleSessionChat
    isDocumentChat
    viewChatRole
    getUsageLimits
    messagesLimit
  }

  {sourceName, messageCollection, sessionListCollection, metaDataCollection, usageLimitCollection, sessionListDataOptions, isSingleSessionChat, isDocumentChat, workspaceAPI, bots}