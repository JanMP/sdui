import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {userWithIdIsInRole} from '../common/roleChecks.coffee'
import {ReactiveAggregate} from 'meteor/tunguska:reactive-aggregate'


export createChatPublications = ({
  sourceName, collection, sessionListCollection,
  isSingleSessionChat,
  viewChatRole
}) ->

  return unless Meteor.isServer

  unless collection?
    throw new Error 'no collection given'
  
  Meteor.publish "#{sourceName}.messages", ({sessionId}) ->
    return @ready() unless userWithIdIsInRole id: @userId, role: viewChatRole
    return @ready() unless isSingleSessionChat or  @userId in (sessionListCollection?.findOne(sessionId)?.userIds ? [])
    @autorun (computation) ->
      collection.find {sessionId},
        sort: {createdAt: -1}
        limit: 100