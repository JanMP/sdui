import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {Schema} from '../schema/Schema.coffee'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {createTableDataAPI} from '../api/createTableDataAPI.coffee'
import {currentUserMustBeInRole} from '../common/roleChecks.coffee'
import {LongTextField} from '../forms/uniforms-custom/select-implementation'
import _ from 'lodash'

###*
  Creates and configures an API for managing Question and Answer articles,
  including operations for viewing, adding, and editing entries. The API setup
  includes database collection definitions, schema validation, and role-based
  permissions for operations. Additionally, it involves embedding vectors for
  questions to support features like semantic search or similarity matching.

  @param {Object} options - Configuration options for the API
  @param {String} options.sourceName - Unique identifier for the source of the data
  @param {Mongo.Collection} options.collection - The MongoDB collection to store QA articles
  @param {String} options.viewTableRole - Role required to view the QA articles table
  @param {String} options.editRole - Role required for editing QA articles
  @param {Object} options.embeddingModelSettings - Settings for the embedding model used for vectorization
  @param {'import("../customTypes").Role'} [options.agentRole] - Optional Role for the agent that can perform operations
  @return {Object} Configured API object for managing QA articles data
  ###
export createQAArticlesAPI = ({sourceName, collection, viewTableRole, editRole, embeddingModelSettings, agentRole}) ->

  sourceSchema = new Schema
    type: 'object'
    properties:
      question:
        title: 'Frage'
        type: 'string'
        uniforms:
          component: LongTextField
      answer:
        title: 'Antwort'
        type: 'string'
        uniforms:
          component: LongTextField
      vector:
        type: 'array'
        items: type: 'number'
    required: ['question', 'answer']

  listSchema = sourceSchema.omit ['vector']


  # TODO make sdai availble to makeSubmitMethodRunFkt internally in createTableDataAPI
  sdAiSettings =
    embeddingModelSettings: embeddingModelSettings
    getEmbeddingContext: ({document}) -> document.question
    agentRole: agentRole


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