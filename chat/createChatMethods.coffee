import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import SimpleSchema from 'simpl-schema'
import {currentUserMustBeInRole, currentUserIsInRole} from '../common/roleChecks.coffee'

import _ from 'lodash'

export createChatMethods = ({
  sourceName, collection, sessionListCollection,
  viewChatRole, addSessionRole
}) ->

  new ValidatedMethod
    name: "#{sourceName}.addSession"
    validate:
      new SimpleSchema
        title:
          type: String
          optional: true
        users:
          type: Array
          optional: true
        'users.$':
          type: String
      .validator()
    run: ({title, users}) ->
      currentUserMustBeInRole addSessionRole
      return unless Meteor.isServer
      title ?= '[no title]'
      userIds = [Meteor.userId()]
      sessionListCollection.insert {title, userIds}

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
      sessionSettings = sessionListCollection.findOne sessionId
      unless sessionSettings?
        throw new Meteor.Error 'no session found'
      unless Meteor.userId() in sessionSettings.userIds
        throw new Meteor.Error 'user not in session'
      collection.insert
        userId: Meteor.userId()
        sessionId: sessionId
        text: text
        createdAt: new Date()
        chatRole: 'user'


  new ValidatedMethod
    name: "#{sourceName}.sessions.addSingleUserSession"
    validate:
      new SimpleSchema
        title:
          type: String
          optional: true
      .validator()
    run: ({title}) ->
      currentUserMustBeInRole addSessionRole
      return unless Meteor.isServer
      title ?= '[no title]'
      userIds = [Meteor.userId()]
      sessionListCollection.insert {title, userIds}


  new ValidatedMethod
    name: "#{sourceName}.sessions.deleteSession"
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