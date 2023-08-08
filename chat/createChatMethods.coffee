import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import SimpleSchema from 'simpl-schema'
import {currentUserMustBeInRole, currentUserIsInRole} from '../common/roleChecks.coffee'

import _ from 'lodash'

export createChatMethods = ({
  sourceName, collection, sessionListCollection, isSingleSessionChat,
  viewChatRole, addSessionRole, reactToNewMessage, onNewSession
}) ->

  reactToNewMessage ?= ({text, messageId, sessionId}) ->
  onNewSession ?= ({sessionId}) -> console.log 'onNewSession', {sessionId}

  addSession = ({title, userIds}) ->
    currentUserMustBeInRole addSessionRole
    return unless Meteor.isServer
    title ?= '[no title]'
    userIds ?= [Meteor.userId()]
    sessionId = sessionListCollection.insert {title, userIds}
    onNewSession {sessionId}
    sessionId

  getSingleSession = ->
    currentUserMustBeInRole viewChatRole
    return unless Meteor.isServer
    sessionId = Meteor.userId()
    unless collection.findOne sessionId: sessionId
      onNewSession {sessionId}
    sessionId

  deleteSingleSession = ->
    currentUserMustBeInRole viewChatRole
    return unless Meteor.isServer
    sessionId = Meteor.userId()
    collection.remove {sessionId}


  new ValidatedMethod
    name: "#{sourceName}.addMessage"
    validate:
      new SimpleSchema
        text:
          type: String
        sessionId:
          type: String
      .validator()
    run: ({text, sessionId}) ->
      currentUserMustBeInRole viewChatRole
      return unless Meteor.isServer
      unless isSingleSessionChat
        sessionSettings = sessionListCollection?.findOne sessionId
        unless sessionSettings?
          throw new Meteor.Error 'no session found'
        unless Meteor.userId() in sessionSettings.userIds
          throw new Meteor.Error 'user not in session'
      newMessage =
        userId: Meteor.userId()
        sessionId: if isSingleSessionChat then Meteor.userId() else sessionId
        text: text
        createdAt: new Date()
        chatRole: 'user'
      messageId = collection.insert newMessage
      reactToNewMessage {newMessage..., messageId}
      messageId


  # we don't use this one yet, we use .sessions.addSingleUserSession as a shortcut (we don't have a UI to add users to a chat yet)
  new ValidatedMethod
    name: "#{sourceName}.addSession"
    validate:
      new SimpleSchema
        title:
          type: String
          optional: true
        userIds:
          type: Array
          optional: true
        'userIds.$':
          type: String
      .validator()
    run: addSession


  new ValidatedMethod
    name: "#{sourceName}.deleteSession"
    validate:
      new SimpleSchema
        id:
          type: String
      .validator()
    run: ({id}) ->
      currentUserMustBeInRole addSessionRole
      return unless Meteor.isServer
      collection.remove sessionId: id
      sessionListCollection.remove id
  
  # we look for any session for this user and return the id, so we can select it in the UI
  # if there is no session yet, we create one
  new ValidatedMethod
    name: "#{sourceName}.initialSessionForChat"
    validate: null
    run: ->
      return unless Meteor.isServer
      if isSingleSessionChat
        return getSingleSession()
      currentUserMustBeInRole addSessionRole
      if (existingSession = sessionListCollection?.findOne userIds: [Meteor.userId()])?
        return existingSession._id
      addSession {}

  new ValidatedMethod
    name: "#{sourceName}.resetSingleSession"
    validate: null
    run: ->
      currentUserMustBeInRole viewChatRole
      return unless Meteor.isServer
      deleteSingleSession()
      getSingleSession()
