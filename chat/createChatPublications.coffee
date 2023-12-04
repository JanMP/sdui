import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {userWithIdIsInRole} from '../common/roleChecks.coffee'
import {ReactiveAggregate} from 'meteor/tunguska:reactive-aggregate'
import {Tacker} from 'meteor/tracker'

###*
  @param {Object} options
  @param {String} options.sourceName
  @param {Mongo.Collection} options.messageCollection
  @param {Mongo.Collection} options.sessionListCollection
  @param {Mongo.Collection} [options.metaDataCollection]
  @param {Boolean} [options.isSingleSessionChat]
  @param {String} [options.viewChatRole]
  @param {Function} [options.getUsageLimits]
  @param {Number} [options.messagesLimit] - max number of messages to be published
  ###
export createChatPublications = ({
  sourceName,
  messageCollection, sessionListCollection, metaDataCollection
  isSingleSessionChat,
  viewChatRole
  getUsageLimits
  messagesLimit = 100
}) ->

  return unless Meteor.isServer

  unless messageCollection?
    throw new Error 'no collection given'

  Meteor.publish "#{sourceName}.messages", ({sessionId}) ->
    return @ready() unless sessionId?
    return @ready() unless userWithIdIsInRole id: @userId, role: viewChatRole
    return @ready() unless @userId in (sessionListCollection?.findOne(sessionId)?.userIds ? [])
    @autorun (computation) ->
      query =
        sessionId: sessionId
        chatRole: $in: ['user', 'assistant']
      messageCollection.find query,
        sort: {createdAt: -1}
        limit: messagesLimit

  Meteor.publish "#{sourceName}.metaData", ({sessionId}) ->
    return @ready() unless sessionId?
    return @ready() unless metaDataCollection?
    return @ready() unless userWithIdIsInRole id: @userId, role: viewChatRole
    return @ready() unless isSingleSessionChat or  @userId in (sessionListCollection?.findOne(sessionId)?.userIds ? [])
    @autorun (computation) ->
      metaDataCollection.find {sessionId},
        sort: {createdAt: -1}
        limit: 100

  Meteor.publish "#{sourceName}.usageLimits", ({sessionId}) ->

    return @ready() unless sessionId?
    return @ready() unless getUsageLimits?()?
    return @ready() unless userWithIdIsInRole id: @userId, role: viewChatRole

    @autorun (computation) ->

      limits = getUsageLimits()
      maxMessagesPerDay = limits?.maxMessagesPerDay ? 100
      maxSessionsPerDay = limits?.maxSessionsPerDay ? 20
      maxMessagesPerSession = limits?.maxMessagesPerSession ? 20
      maxMessageLength = limits?.maxMessageLength ? 1000

      unless messageCollection.findOne userId: @userId
        @added "#{sourceName}.usageLimits", @userId, {
          _id: @userId
          sessionId, maxMessageLength, maxMessagesPerDay, maxSessionsPerDay, maxMessagesPerSession
          numberOfMessagesToday: 0
          numberOfMessagesThisSession: 0
          messagesPerDayLeft: maxMessagesPerDay
          sessionsPerDayLeft: maxSessionsPerDay
          messagesPerSessionLeft: maxMessagesPerSession
        }
      else
        ReactiveAggregate this, messageCollection,
          [
            $match:
              userId: @userId
              chatRole: 'user'
          ,
            $group:
              _id: null
              numberOfMessagesToday:
                $sum:
                  $cond:
                    if: $gte: ['$createdAt', new Date(new Date().setHours(0,0,0,0))]
                    then: 1
                    else: 0
              numberOfMessagesThisSession:
                $sum:
                  $cond:
                    if: $eq: ['$sessionId', sessionId]
                    then: 1
                    else: 0
              sessionsToday:
                $addToSet:
                  $cond:
                    if: $gte: ['$createdAt', new Date(new Date().setHours(0,0,0,0))]
                    then: '$sessionId'
                    else: null
          ,
            $addFields:
              numberOfSessionsToday: {$size: '$sessionsToday'}
          ,
            $addFields:
              _id: sessionId ? @userId
              sessionId: sessionId
              maxMessageLength: maxMessageLength
              maxMessagesPerDay: maxMessagesPerDay
              maxSessionsPerDay: maxSessionsPerDay
              messagesPerDayLeft: {$subtract: [maxMessagesPerDay, '$numberOfMessagesToday']}
              sessionsPerDayLeft: {$subtract: [maxSessionsPerDay, '$numberOfSessionsToday']}
              messagesPerSessionLeft: {$subtract: [maxMessagesPerSession, '$numberOfMessagesThisSession']}
          ],
          clientCollection: "#{sourceName}.usageLimits"
          debounceDelay: 200
          noAutomaticObserver: true
          observers: [messageCollection.find {userId: @userId}]