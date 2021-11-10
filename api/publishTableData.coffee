import {Meteor} from 'meteor/meteor'
import { ReactiveAggregate } from 'meteor/tunguska:reactive-aggregate'
import {userWithIdIsInRole} from '../common/roleChecks.coffee'

export default publishTableData = ({viewTableRole, sourceName, collection,
getRowsPipeline, getRowCountPipeline, debounceDelay = 500})  ->
  if Meteor.isServer
  
    unless collection?
      throw new Error 'no collection given'

    Meteor.publish "#{sourceName}.rows", ({search, query, sort, limit, skip}) ->
      return @ready() unless userWithIdIsInRole id: @userId, role: viewTableRole
      @autorun (computation) ->
        pipeline = getRowsPipeline {pub: this, search, query, sort, limit, skip}
        ReactiveAggregate this, collection,
          pipeline,
          clientCollection: "#{sourceName}.rows"
          debounceDelay: debounceDelay
   
    Meteor.publish "#{sourceName}.count", ({search, query = {}}) ->
      return @ready() unless userWithIdIsInRole id: @userId, role: viewTableRole
      pipeline = getRowCountPipeline {pub: this, search , query}
      @autorun (computation) ->
        ReactiveAggregate this, collection,
          pipeline,
          clientCollection: "#{sourceName}.count"
          dbounceDelay: debounceDelay
