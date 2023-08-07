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
  text:
    type: String
  createdAt:
    type: Date
  chatRole:
    type: String
    allowedValues: ['user', 'bot', 'system']
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

export createChatAPI = ({
  sourceName
  collection
  sessionListCollection
  viewChatRole, addSessionRole,
  bots, reactToNewMessage, onNewSession
}) ->

  # check required props and setup defaults for optional props
  unless sourceName?
    throw new Error 'no sourceName given'
  
  unless collection?
    throw new Error 'no collection given'
  
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

  sessionListDataOptions =
    createChatSessionListAPI {
      sourceName
      sessionListCollection
      viewChatRole
      addSessionRole
    }

  createChatMethods {
    sourceName
    collection
    sessionListCollection
    viewChatRole
    addSessionRole
    reactToNewMessage
    onNewSession
  }

  createChatPublications {
    sourceName
    collection
    sessionListCollection
    viewChatRole
  }

  {sourceName, collection, sessionListDataOptions, bots}