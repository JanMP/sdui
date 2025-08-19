import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {createTableDataAPI, LongTextField, Schema} from 'meteor/janmp:sdui'

###*
  This file defines the Prompts collection and its API.
  This is just a wrapper around the createTableDataAPI function to create a table for Prompts.
  @param {Object} options - Options for the API.
  @param {string} options.sourceName - the sdui sourceName
  @returns {Object} - the sdui createTableDataAPI dataOptions
  ###
export createPromptsTableAPI = ({
  sourceName, viewTableRole, editRole, articleCategories
}) ->

  Prompts = new Mongo.Collection "#{sourceName}.prompts"

  sourceSchema = new Schema
    type: 'object'
    properties:
      promptType:
        type: 'string'
        enum: articleCategories #wtf, this removes capitalization?!
        uniforms:
          disabled: true
      text:
        type: 'string'
        uniforms:
          component: LongTextField
          rows: 15
          cols: 60
    required: ['promptType', 'text']

  if Meteor.isServer
    do ->
      unless (await Prompts.find().fetchAsync())?.length
        console.log 'start seeding prompts'
        articleCategories.forEach (category) ->
          console.log "inserting prompt for category #{category}"
          await Prompts.insertAsync
            promptType: category
            text: ''

  dataOptions = createTableDataAPI
    sourceName: "#{sourceName}.prompts"
    sourceSchema: sourceSchema
    collection: Prompts
    viewTableRole: viewTableRole
    editRole: editRole
    canEdit: true
    canDelete: false
    canAdd: false
    usePubSub: true
