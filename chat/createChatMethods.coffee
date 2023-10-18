import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import SimpleSchema from 'simpl-schema'
import {currentUserMustBeInRole, currentUserIsInRole} from '../common/roleChecks.coffee'

import _ from 'lodash'

###*
  @param {Object} options
  @param {String} options.sourceName
  @param {Mongo.Collection} options.collection
  @param {Mongo.Collection} options.sessionListCollection
  @param {Mongo.Collection} [options.metaDataCollection]
  @param {Mongo.Collection} [options.logCollection]
  @param {Boolean} [options.isSingleSessionChat]
  @param {String} [options.viewChatRole]
  @param {String} [options.addSessionRole]
  @param {Function} [options.reactToNewMessage]
  @param {Function} [options.onNewSession]
  @param {Function} [options.getUsageLimits]
  ###
export createChatMethods = ({
  sourceName
  collection, sessionListCollection, metaDataCollection, logCollection
  isSingleSessionChat,
  viewChatRole, addSessionRole,
  reactToNewMessage, onNewSession
  getUsageLimits
}) ->

  reactToNewMessage ?= ({text, messageId, sessionId}) ->
  onNewSession ?= ({sessionId}) -> console.log 'onNewSession', {sessionId}


  messagesPerDayLimitReached =  ->
    return false unless logCollection? and getUsageLimits?()?.maxMessagesPerDay?
    limit = getUsageLimits().maxMessagesPerDay
    messagesByUserToday =
      logCollection?.find
        userId: Meteor.userId()
        createdAt:
          $gte: new Date(new Date().setHours(0,0,0,0))
      .count()
    messagesByUserToday >= limit

  sessionsPerDayLimitReached =  ->
    return false unless logCollection? and getUsageLimits?()?.maxSessionsPerDay?
    limit = getUsageLimits().maxSessionsPerDay
    sessionsByUserToday =
      _(
        logCollection?.find
          userId: Meteor.userId()
          createdAt:
            $gte: new Date(new Date().setHours(0,0,0,0))
        .map (logEntry) -> logEntry.sessionId
      ).uniq().value().length
    sessionsByUserToday >= limit

  messagesPerSessionLimitReached = ({sessionId}) ->
    return false unless logCollection? and getUsageLimits?()?.maxMessagesPerSession?
    limit = getUsageLimits().maxMessagesPerSession
    messagesPerSession =
      logCollection?.find
        userId: Meteor.userId()
        sessionId: sessionId
      .count()
    messagesPerSession >= limit

  textTooLong = ({text}) ->
    return false unless getUsageLimits()?.maxMessageLength?
    text.length > getUsageLimits().maxMessageLength
  
  addSession = ({title, userIds}) ->
    if sessionsPerDayLimitReached()
      throw new Meteor.Error "Tut uns Leid, wir erlauben momentan nur #{getUsageLimits()?.maxSessionsPerDay} Chats pro Tag. Bitte versuche es morgen nochmal."
    currentUserMustBeInRole addSessionRole
    return unless Meteor.isServer
    title ?= '[no title]'
    userIds ?= [Meteor.userId()]
    sessionId = sessionListCollection.insert {title, userIds, createdAt: new Date()}
    onNewSession {sessionId}
    sessionId

  new ValidatedMethod
    name: "#{sourceName}.addMessage"
    validate:
      new SimpleSchema
        text:
          type: String
        sessionId:
          type: String
          optional: true
      .validator()
    run: ({text, sessionId}) ->
      currentUserMustBeInRole viewChatRole
      return unless Meteor.isServer
      if messagesPerDayLimitReached()
        throw new Meteor.Error "Tut uns Leid, wir erlauben momentan nur #{getUsageLimits()?.maxMessagesPerSession} Nachrichten pro Tag. Bitte versuche es morgen nochmal."
      if messagesPerSessionLimitReached {sessionId}
        throw new Meteor.Error "Tut uns Leid, wir erlauben momentan nur #{getUsageLimits()?.maxMessagesPerSession} Nachrichten pro Chat."
      if textTooLong {text}
        throw new Meteor.Error "Tut uns Leid, wir erlauben momentan nur #{usageLimits.maxMessageLength} Zeichen pro Nachricht. Bitte versuche es nochmal mit einer kürzeren Nachricht."
      unless isSingleSessionChat
        unless sessionId?
          throw new Meteor.Error 'no sessionId for non-singleSessionChat given'
        sessionSettings = sessionListCollection?.findOne sessionId
        unless sessionSettings?
          throw new Meteor.Error 'no session found'
        unless Meteor.userId() in sessionSettings.userIds
          throw new Meteor.Error 'user not in session'
      newMessage =
        userId: Meteor.userId()
        sessionId: sessionId
        text: text
        createdAt: new Date()
        chatRole: 'user'
      messageId = collection.insert newMessage
      reactToNewMessage {newMessage..., messageId}
      messageId


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
      metaDataCollection.remove sessionId: id
      sessionListCollection.remove id
  
  # we look for any session for this user and return the id, so we can select it in the UI
  # if there is no session yet, we create one
  new ValidatedMethod
    name: "#{sourceName}.initialSessionForChat"
    validate: null
    run: ->
      return unless Meteor.isServer
      currentUserMustBeInRole addSessionRole
      if (existingSession = sessionListCollection?.findOne {userIds: [Meteor.userId()]}, sort: createdAt: -1)?
        return existingSession._id
      addSession {}

  new ValidatedMethod
    name: "#{sourceName}.resetSingleSession"
    validate: null
    run: ->
      currentUserMustBeInRole viewChatRole
      return unless Meteor.isServer
      if (existingSession = sessionListCollection?.findOne {userIds: [Meteor.userId()]}, sort: createdAt: -1)?
        metaDataCollection.remove sessionId: existingSession._id
        sessionListCollection.remove existingSession._id
      addSession {}
