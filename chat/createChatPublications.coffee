import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {userWithIdIsInRole} from '../common/roleChecks.coffee'
import {ReactiveAggregate} from 'meteor/tunguska:reactive-aggregate'
import {Tacker} from 'meteor/tracker'

###*
  @param {Object} options
  @param {String} options.sourceName
  @param {Mongo.Collection} options.collection
  @param {Mongo.Collection} options.sessionListCollection
  @param {Mongo.Collection} [options.metaDataCollection]
  @param {Mongo.Collection} [options.logCollection]
  @param {Mongo}
  @param {Boolean} [options.isSingleSessionChat]
  @param {String} [options.viewChatRole]
  @param {Function} [options.getUsageLimits]
  ###
export createChatPublications = ({
  sourceName,
  collection, sessionListCollection, metaDataCollection, logCollection
  isSingleSessionChat,
  viewChatRole
  getUsageLimits
}) ->

  return unless Meteor.isServer

  unless collection?
    throw new Error 'no collection given'

  Meteor.publish "#{sourceName}.messages", ({sessionId}) ->
    return @ready() unless sessionId?
    # return @ready() unless userWithIdIsInRole id: @userId, role: viewChatRole
    # return @ready() unless isSingleSessionChat or  @userId in (sessionListCollection?.findOne(sessionId)?.userIds ? [])
    @autorun (computation) ->
      collection.find {sessionId},
        sort: {createdAt: -1}
        limit: 100

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
    return @ready() unless logCollection?
    # return @ready() unless getUsageLimits?()?
    return @ready() unless userWithIdIsInRole id: @userId, role: viewChatRole

    @autorun (computation) ->

      limits = getUsageLimits()
      maxMessagesPerDay = limits?.maxMessagesPerDay ? 100
      maxSessionsPerDay = limits?.maxSessionsPerDay ? 20
      maxMessagesPerSession = limits?.maxMessagesPerSession ? 20
      maxMessageLength = limits?.maxMessageLength ? 1000

      ReactiveAggregate this, logCollection,
        [
          $match:
            userId: @userId
            createdAt:
              $gte: new Date(new Date().setHours(0,0,0,0))
        ,
          $group:
            _id: null
            numberOfMessagesToday:
              $sum:
                $cond:
                  if: {$eq: ['$message.role', 'user']}
                  then: 1
                  else: 0
            numberOfMessagesThisSession:
              $sum:
                $cond:
                  if: {$eq: ['$sessionId', sessionId]}
                  then:
                    $cond:
                      if: {$eq: ['$message.role', 'user']}
                      then: 1
                      else: 0
                  else: 0
            sessionsToday: $addToSet: '$sessionId'
        ,
          $addFields:
            numberOfSessionsToday: {$size: '$sessionsToday'}
        ,
          $addFields:
            _id: sessionId
            maxMessageLength: maxMessageLength
            messagesPerDayLeft: {$subtract: [maxMessagesPerDay, '$numberOfMessagesToday']}
            sessionsPerDayLeft: {$subtract: [maxSessionsPerDay, '$numberOfSessionsToday']}
            messagesPerSessionLeft: {$subtract: [maxMessagesPerSession, '$numberOfMessagesThisSession']}
        ]
        clientCollection: "#{sourceName}.usageLimits"
        debounceDelay: 200
        observers: []