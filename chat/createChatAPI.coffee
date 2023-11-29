import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {createChatMethods} from './createChatMethods'
import {createChatPublications} from './createChatPublications'
import SimpleSchema from 'simpl-schema'
import {createChatSessionListAPI} from './createChatSessionListAPI'

export chatSchema = new SimpleSchema
  userId:
    type: String
  sessionId:
    type: String
  createdAt:
    type: Date
  text:
    type: String
  chatRole:
    type: String
    allowedValues: ['user', 'assistant', 'system', 'log']
  usage:
    type: Object
    optional: true
  'usage.model':
    type: String
  'usage.prompt':
    type: Number
  'usage.completion':
    type: Number
  workInProgress:
    type: Boolean
    optional: true
  feedback:
    type: Object
    optional: true
  'feedback.thumbs':
    type: String
    allowedValues: ['up', 'down']
    optional: true
  'feedback.comment':
    type: String
    optional: true

export chatMetaDataSchema = new SimpleSchema
  sessionId: String
  createdAt: Date
  type: String
  data:
    type: Object
    blackbox: true

###*
  @param {Object} options
  @param {String} options.sourceName
  @param {Mongo.Collection} options.messageCollection
  @param {Mongo.Collection} options.sessionListCollection
  @param {Mongo.Collection} [options.metaDataCollection]
  @param {Mongo.Collection} [options.usageLimitCollection]
  @param {Boolean} [options.isSingleSessionChat]
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
  viewChatRole, addSessionRole,
  bots, reactToNewMessage, onNewSession
  messagesLimit = 100
  getUsageLimits = ->
}) ->


  # check required props and setup defaults for optional props
  unless sourceName?
    throw new Error 'no sourceName given'
  
  unless messageCollection?
    throw new Error 'no messageCollection given'
  
  unless sessionListCollection? or isSingleSessionChat
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
    viewChatRole
    getUsageLimits
    messagesLimit
  }

  {sourceName, messageCollection, sessionListCollection, metaDataCollection, usageLimitCollection, sessionListDataOptions, isSingleSessionChat, bots}