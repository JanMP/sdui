import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {Schema} from '../schema/Schema.coffee'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {createTableDataAPI} from '../api/createTableDataAPI.coffee'
import {currentUserMustBeInRole} from '../common/roleChecks.coffee'
import {LongTextField} from '../forms/uniforms-custom/select-implementation'

import _ from 'lodash'


###*
  # Creates and configures an API for managing Question and Answer articles,
  # including operations for viewing, adding, and editing entries. The API setup
  # includes database collection definitions, schema validation, and role-based
  # permissions for operations. Additionally, it involves embedding vectors for
  # questions to support features like semantic search or similarity matching.
  #
  # @param {Object} options - Configuration options for the API
  # @param {String} options.sourceName - Unique identifier for the source of the data
  # @param {Mongo.Collection} options.collection - The MongoDB collection to store QA articles
  # @param {String} options.viewTableRole - Role required to view the QA articles table
  # @param {String} options.editRole - Role required for editing QA articles
  # @param {Function} options.getEmbedding - Function to generate embedding vectors for questions
  # @return {Object} Configured API object for managing QA articles data
  ###
export createQAArticlesAPI = ({sourceName, collection, viewTableRole, editRole, getEmbedding}) ->

  sourceSchema = new Schema
    type: 'object'
    properties:
      question:
        type: 'string'
        uniforms:
          label: 'Frage'
          component: LongTextField
      answer:
        type: 'string'
        uniforms:
          label: 'Antwort'
          component: LongTextField
      vector:
        type: 'array'
        items: type: 'number'
    required: ['question', 'answer']

  listSchema = sourceSchema.omit ['vector']

  # TODO make sdai availble to makeSubmitMethodRunFkt internally in createTableDataAPI
  sdAiSettings =
    embeddingModelSettings: Meteor.settings.embeddingCP
    getEmbeddingContext: ({document}) -> document.question


  # if false and Meteor.isServer and not Meteor.isDevelopment
  #   await collection.find().forEachAsync (document) ->
  #     console.log "update vector for #{sourceName}, #{document.question}"
  #     vector =
  #       try
  #         await getEmbedding text: document.question
  #       catch error
  #         console.error error
  #         throw new Meteor.Error "[#{sourceName} #{document.question}] Could not get embedding"
  #     collection.updateAsync document._id, $set: vector: vector


  createTableDataAPI
    sourceName: sourceName
    collection: collection
    sourceSchema: sourceSchema
    listSchema: listSchema
    viewTableRole: viewTableRole
    editRole: editRole
    canEdit: true
    canAdd: true
    canDelete: true
    canExport: true
    canKnnSearch: true
    initialSortColumn: 'question'
    initialSortDirection: 'ASC'
    sdAiSettings: sdAiSettings
    makeSubmitMethodRunFkt: ({collection, transformIdToMongo, transformIdToMiniMongo}) ->
      ({data, id}) ->
        vector =
          try
            await getEmbedding text: data.question
          catch error
            console.error error
            throw new Meteor.Error "[#{sourceName}.submit] Could not get embedding"
        await collection.upsertAsync (transformIdToMongo id), $set: {data..., vector: vector}