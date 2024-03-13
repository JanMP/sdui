import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import SimpleSchema from 'simpl-schema'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
# import {createTableDataAPI, currentUserMustBeInRole, LongTextField} from 'meteor/janmp:sdui'
import {createTableDataAPI} from '../api/createTableDataAPI.coffee'
import {currentUserMustBeInRole} from '../common/roleChecks.coffee'
import {LongTextField} from '../forms/uniforms-custom/select-implementation'

import _ from 'lodash'

SimpleSchema.extendOptions(['sdTable', 'uniforms'])

sourceSchemaDefinition =
  question:
    type: String
    label: 'Frage'
    uniforms: LongTextField
    optional: false
  answer:
    type: String
    label: 'Antwort'
    uniforms: LongTextField
    optional: false
  vector:
    type: Array
    label: 'Vector'
  'vector.$':
    type: Number

sourceSchema = new SimpleSchema sourceSchemaDefinition
listSchema = new SimpleSchema _.pick sourceSchemaDefinition, ['question', 'answer']

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
  createTableDataAPI
    sourceName: sourceName
    collection: collection
    sourceSchema: sourceSchema
    listSchema: listSchema
    formSchema: listSchema
    viewTableRole: viewTableRole
    editRole: editRole
    canEdit: true
    canAdd: true
    canDelete: true
    showRowCount: true
    initialSortColumn: 'question'
    initialSortDirection: 'ASC'
    makeSubmitMethodRunFkt: ({collection, transformIdToMongo, transformIdToMiniMongo}) ->
      ({data, id}) ->
        vector =
          try
            await getEmbedding text: data.question
          catch error
            console.error error
            throw new Meteor.Error "[#{sourceName}.submit] Could not get embedding"
        await collection.upsertAsync (transformIdToMongo id), $set: {data..., vector: vector}