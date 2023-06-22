import {Meteor} from 'meteor/meteor'
import {ReactiveAggregate} from 'meteor/tunguska:reactive-aggregate'
import {userWithIdIsInRole} from '../common/roleChecks.coffee'


export publishTableData = ({viewTableRole, sourceName, collection,
getRowsPipeline, getRowCountPipeline, debounceDelay = 500, observers, getKnnIdsAndScore})  ->
  
  if Meteor.isServer

    unless collection?
      throw new Error 'no collection given'

    Meteor.publish "#{sourceName}.rows", ({search, query, queryUiObject, sort, limit, skip}) ->
      return @ready() unless userWithIdIsInRole id: @userId, role: viewTableRole
      @autorun (computation) ->
        knnIdsAndScore = Promise.await getKnnIdsAndScore {search}
        pipeline = getRowsPipeline {pub: this, search, knnIdsAndScore, query, queryUiObject, sort, limit, skip}
        ReactiveAggregate this, collection,
          pipeline,
          clientCollection: "#{sourceName}.rows"
          debounceDelay: debounceDelay
          # noAutomaticObservers: observers?
          observers: observers ? []
   
    Meteor.publish "#{sourceName}.count", ({search, query = {}, queryUiObject}) ->
      return @ready() unless userWithIdIsInRole id: @userId, role: viewTableRole
      knnIdsAndScore = Promise.await getKnnIdsAndScore {search}
      pipeline = getRowCountPipeline {pub: this, search, knnIdsAndScore, query, queryUiObject}
      @autorun (computation) ->
        ReactiveAggregate this, collection,
          pipeline,
          clientCollection: "#{sourceName}.count"
          dbounceDelay: debounceDelay
          # noAutomaticObservers: observers?
          observers: observers ? []
