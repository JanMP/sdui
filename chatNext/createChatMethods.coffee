import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {Schema} from '../schema/Schema.coffee'
import {currentUserMustBeInRole} from '../common/roleChecks.coffee'

import _ from 'lodash'

###*
  @param {Object} options
  @param {String} options.sourceName
  @param {Mongo.Collection} options.messageCollection
  @param {Mongo.Collection} options.sessionListCollection
  @param {Mongo.Collection} [options.metaDataCollection]
  @param {Boolean} [options.isSingleSessionChat]
  @param {Boolean} [options.isDocumentChat]
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
  isDocumentChat,
  viewChatRole, addSessionRole,
  reactToNewMessage, onNewSession
  getUsageLimits
}) ->

  reactToNewMessage ?= ({text, messageId, sessionId}) -> Promise.resolve('no reactToNewMessage function given')
  onNewSession ?= ({sessionId}) -> console.log 'onNewSession', {sessionId}

  messagesPerDayLimitReached =  ->
    return false unless (limit = getUsageLimits?()?.maxMessagesPerDay)?
    messagesByUserToday =
      await messageCollection.find
        userId: Meteor.userId()
        chatRole: 'user'
        createdAt:
          $gte: new Date(new Date().setHours(0,0,0,0))
      .countAsync()
    messagesByUserToday >= limit

  sessionsPerDayLimitReached =  ->
    return false unless (limit = getUsageLimits?()?.maxSessionsPerDay)?
    sessionsByUserToday =
      _(
        await messageCollection.find
          userId: Meteor.userId()
          createdAt:
            $gte: new Date(new Date().setHours(0,0,0,0))
        .mapAsync (logEntry) -> logEntry.sessionId
      ).uniq().value().length
    sessionsByUserToday >= limit

  messagesPerSessionLimitReached = ({sessionId}) ->
    return false unless (limit = getUsageLimits?()?.maxMessagesPerSession)?
    messagesPerSession =
      await messageCollection.find
        userId: Meteor.userId()
        sessionId: sessionId
        chatRole: 'user'
      .countAsync()
    messagesPerSession >= limit

  textTooLong = ({text}) ->
    return false unless getUsageLimits()?.maxMessageLength?
    text.length > getUsageLimits().maxMessageLength

  userIsInSession = ({sessionId}) ->
    Meteor.userId() in (await sessionListCollection?.findOneAsync(sessionId)?.userIds ? [])

  userIsInSessionOfMessage = ({messageId}) ->
    sessionId = (await messageCollection?.findOneAsync(messageId))?.sessionId
    unless sessionId?
      console.log 'no sessionId for message', messageId
      return false
    userIsInSession {sessionId}

  addSession = ({title, userIds, model}) ->
    if await sessionsPerDayLimitReached()
      throw new Meteor.Error "Tut uns Leid, wir erlauben momentan nur #{getUsageLimits()?.maxSessionsPerDay} Chats pro Tag. Bitte versuche es morgen nochmal."
    await currentUserMustBeInRole addSessionRole
    return unless Meteor.isServer
    title ?= '[no title]'
    userIds ?= [Meteor.userId()]
    sessionId = await sessionListCollection.insertAsync {title, userIds, model, createdAt: new Date()}
    onNewSession {sessionId}
    sessionId

  new ValidatedMethod
    name: "#{sourceName}.addMessage"
    validate:
      new Schema
        type: 'object'
        properties:
          text:
            type: 'string'
          sessionId:
            type: 'string'
        required: ['text', 'sessionId']
      .methodValidator
    run: ({text, sessionId}) ->
      await currentUserMustBeInRole viewChatRole
      return unless Meteor.isServer
      unless userIsInSession {sessionId}
        throw new Meteor.Error 'user not in session'
      if await messagesPerDayLimitReached()
        throw new Meteor.Error "Tut uns Leid, wir erlauben momentan nur #{getUsageLimits()?.maxMessagesPerSession} Nachrichten pro Tag. Bitte versuche es morgen nochmal."
      if await messagesPerSessionLimitReached {sessionId}
        throw new Meteor.Error "Tut uns Leid, wir erlauben momentan nur #{getUsageLimits()?.maxMessagesPerSession} Nachrichten pro Chat."
      if textTooLong {text}
        throw new Meteor.Error "Tut uns Leid, wir erlauben momentan nur #{usageLimits.maxMessageLength} Zeichen pro Nachricht. Bitte versuche es nochmal mit einer kürzeren Nachricht."
      newMessage =
        userId: Meteor.userId()
        sessionId: sessionId
        text: text
        createdAt: new Date()
        chatRole: 'user'
      messageId = await messageCollection.insertAsync newMessage
      # @ts-ignore
      reactToNewMessage {newMessage..., messageId}
      .catch (error) ->
        console.error error
        if Meteor.isClient
          throw new Meteor.Error error
      messageId

  new ValidatedMethod
    name: "#{sourceName}.addLogMessage"
    validate:
      new Schema
        type: 'object'
        properties:
          text:
            type: 'string'
          sessionId:
            type: 'string'
        required: ['text', 'sessionId']
      .methodValidator
    run: ({text, sessionId}) -> Promise.resolve "turned off because sanity"
      # await currentUserMustBeInRole viewChatRole
      # return unless Meteor.isServer
      # unless userIsInSession {sessionId}
      #   throw new Meteor.Error 'user not in session'
      # messageCollection.insertAsync
      #   userId: Meteor.userId()
      #   sessionId: sessionId
      #   text: text
      #   createdAt: new Date()
      #   chatRole: 'log'

  new ValidatedMethod
    name: "#{sourceName}.setFeedBackForMessage"
    validate:
      new Schema
        type: 'object'
        properties:
          messageId:
            type: 'string'
          feedback:
            type: 'object'
            properties:
              thumbs:
                type: 'string'
                enum: ['up', 'down']
              comment:
                type: 'string'
            required: ['thumbs']
        required: ['messageId', 'feedback']
      .methodValidator
    run: ({messageId, feedback}) ->
      await currentUserMustBeInRole viewChatRole
      unless userIsInSessionOfMessage {messageId}
        throw new Meteor.Error 'user not in session of message'
      return unless Meteor.isServer
      messageCollection.updateAsync {_id: messageId},
        $set:
          feedback: feedback

  new ValidatedMethod
    name: "#{sourceName}.addSession"
    validate:
      new Schema
        type: 'object'
        properties:
          title:
            type: 'string'
          documentId:
            type: 'string'
          userIds:
            type: 'array'
            items: type: 'string'
        required: ['title']
      .methodValidator
    run: addSession

  # TODO delete for good unless session has user messages
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

  deleteSessionData = ({sessionId}) ->
    if (existingSession = await sessionListCollection?.findOneAsync sessionId)?
      messageCollection.removeAsync {sessionId}
      metaDataCollection.removeAsync {sessionId}
      sessionListCollection.removeAsync {_id: sessionId}

  new ValidatedMethod
    name: "#{sourceName}.deleteSession"
    validate:
      new Schema
        type: 'object'
        properties:
          id: type: 'string'
        required: ['id']
      .methodValidator
    run: ({id}) ->
      await currentUserMustBeInRole addSessionRole
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
      await currentUserMustBeInRole addSessionRole
      if (existingSession = await getExistingSession())?
        return existingSession._id
      addSession {}

  getExistingSessionForDocumentId = ({documentId}) ->
    query =
      userIds: [Meteor.userId()]
      documentId: documentId
      archived: {$ne: true}
    sessionListCollection
    ?.findOneAsync query, sort: createdAt: -1

  new ValidatedMethod
    name: "#{sourceName}.initialSessionForDocumentId"
    validate:
      new Schema
        type: 'object'
        properties:
          documentId: type: 'string'
        required: ['documentId']
      .methodValidator
    run: ({documentId}) ->
      await currentUserMustBeInRole addSessionRole
      return unless Meteor.isServer
      if (existingSession = await getExistingSessionForDocumentId {documentId})?
        return existingSession._id
      addSession {documentId, title: "Chat about document #{documentId}"}

  # TODO: verhindern dass Neon uns weiter die DB zumüllt
  new ValidatedMethod
    name: "#{sourceName}.resetSingleSession"
    validate: null
    run: ->
      await currentUserMustBeInRole viewChatRole
      return unless Meteor.isServer
      if (existingSession = await getExistingSession())?
        archiveSessionData {sessionId: existingSession._id}
      addSession {}
