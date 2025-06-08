import {Meteor} from 'meteor/meteor'
import {ReactiveAggregate} from 'meteor/tunguska:reactive-aggregate'
import {userWithIdIsInRole, currentUserIsInRole} from '../common/roleChecks.coffee'

export publishTableData = ({viewTableRole, sourceName, collection,
getRowsPipeline, noAutomaticObserver = false, debounceDelay = 200, getObservers})  ->

  if Meteor.isServer

    unless collection?
      throw new Error 'no collection given'

    Meteor.publish "#{sourceName}.rows", ({search, query, sort, limit, skip}) ->
      return @ready() unless await currentUserIsInRole viewTableRole
      pipeline = => getRowsPipeline {pub: this, search, query, sort, limit, skip}
      ReactiveAggregate this, collection,
        pipeline,
        clientCollection: "#{sourceName}.rows"
        debounceDelay: debounceDelay
        noAutomaticObserver: noAutomaticObserver
        observers: await getObservers?() ? []