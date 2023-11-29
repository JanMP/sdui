import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import SimpleSchema from 'simpl-schema'
import {currentUserMustBeInRole, currentUserIsInRole} from '../common/roleChecks.coffee'

import _ from 'lodash'

###*
  @param {Object} options
  @param {String} options.sourceName
  @param {Mongo.Collection} options.messageCollection
  @param {Mongo.Collection} options.sessionListCollection
  @param {Mongo.Collection} [options.metaDataCollection]
  @param {Boolean} [options.isSingleSessionChat]
  @param {String} [options.viewChatRole]
  @param {String} [options.addSessionRole]
  @param {Function} [options.reactToNewMessage]
  @param {Function} [options.onNewSession]
  @param {Function} [options.getUsageLimits]
  ###
export createChatMethods = ({
  sourceName
  messageCollection, sessionListCollection, metaDataCollection
  isSingleSessionChat,
  viewChatRole, addSessionRole,
  reactToNewMessage, onNewSession
  getUsageLimits
}) ->

  reactToNewMessage ?= ({text, messageId, sessionId}) ->
  onNewSession ?= ({sessionId}) -> console.log 'onNewSession', {sessionId}


  messagesPerDayLimitReached =  -> false
    # return false unless logCollection? and getUsageLimits?()?.maxMessagesPerDay?
    # limit = getUsageLimits().maxMessagesPerDay
    # messagesByUserToday =
    #   logCollection?.find
    #     userId: Meteor.userId()
    #     'message.role': 'user'
    #     createdAt:
    #       $gte: new Date(new Date().setHours(0,0,0,0))
    #   .count()
    # messagesByUserToday >= limit

  sessionsPerDayLimitReached =  -> false
    # return false unless logCollection? and getUsageLimits?()?.maxSessionsPerDay?
    # limit = getUsageLimits().maxSessionsPerDay
    # sessionsByUserToday =
    #   _(
    #     logCollection?.find
    #       userId: Meteor.userId()
    #       createdAt:
    #         $gte: new Date(new Date().setHours(0,0,0,0))
    #     .map (logEntry) -> logEntry.sessionId
    #   ).uniq().value().length
    # sessionsByUserToday >= limit

  messagesPerSessionLimitReached = ({sessionId}) -> false
    # return false unless logCollection? and getUsageLimits?()?.maxMessagesPerSession?
    # limit = getUsageLimits().maxMessagesPerSession
    # messagesPerSession =
    #   logCollection?.find
    #     userId: Meteor.userId()
    #     sessionId: sessionId
    #     'message.role': 'user'
    #   .count()
    # messagesPerSession >= limit

  textTooLong = ({text}) -> false
    # return false unless getUsageLimits()?.maxMessageLength?
    # text.length > getUsageLimits().maxMessageLength

  userIsInSession = ({sessionId}) ->
    Meteor.userId() in (await sessionListCollection?.findOneAsync(sessionId)?.userIds ? [])

  userIsInSessionOfMessage = ({messageId}) ->
    sessionId = (await messageCollection?.findOneAsync(messageId))?.sessionId
    unless sessionId?
      console.log 'no sessionId for message', messageId
      return false
    userIsInSession {sessionId}
  
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
      unless {sessionId}
        throw new Meteor.Error 'no sessionId given'
      unless userIsInSession {sessionId}
        throw new Meteor.Error 'user not in session'
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
      messageId = messageCollection.insert newMessage
      try
        await reactToNewMessage {newMessage..., messageId}
      catch error
        throw new Meteor.Error error.message, 'Error while trying to react to new message from user'
      messageId

  new ValidatedMethod
    name: "#{sourceName}.setFeedBackForMessage"
    validate:
      new SimpleSchema
        messageId:
          type: String
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
      .validator()
    run: ({messageId, feedback}) ->
      currentUserMustBeInRole viewChatRole
      unless userIsInSessionOfMessage {messageId}
        throw new Meteor.Error 'user not in session of message'
      return unless Meteor.isServer
      messageCollection.update {_id: messageId},
        $set:
          feedback: feedback

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

  archiveSessionData = ({sessionId}) ->
    if (existingSession = await sessionListCollection?.findOneAsync sessionId)?
      messageCollection.updateAsync {sessionId},
        $set:
          archived: true
      , multi: true
      metaDataCollection.updateAsync {sessionId},
        $set:
          archived: true
      , multi: true
      sessionListCollection.updateAsync {_id: sessionId},
        $set:
          archived: true

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
      archiveSessionData {sessionId: id}
  

  getExistingSession = ->
    query =
      userIds: [Meteor.userId()]
      archived: {$ne: true}
    sessionListCollection
    ?.findOneAsync query, sort: createdAt: -1

  # we look for any session for this user and return the id, so we can select it in the UI
  # if there is no session yet, we create one
  new ValidatedMethod
    name: "#{sourceName}.initialSessionForChat"
    validate: null
    run: ->
      return unless Meteor.isServer
      currentUserMustBeInRole addSessionRole
      if (existingSession = await getExistingSession())?
        return existingSession._id
      addSession {}

  new ValidatedMethod
    name: "#{sourceName}.resetSingleSession"
    validate: null
    run: ->
      currentUserMustBeInRole viewChatRole
      return unless Meteor.isServer
      if (existingSession = await getExistingSession())?
        archiveSessionData {sessionId: existingSession._id}
      addSession {}
