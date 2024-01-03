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