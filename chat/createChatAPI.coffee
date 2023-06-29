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

export createChatAPI = ({
  sourceName
  collection
  sessionListCollection
  viewChatRole, addSessionRole
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
  }

  createChatPublications {
    sourceName
    collection
    sessionListCollection
    viewChatRole
  }

  {sourceName, collection, sessionListDataOptions}