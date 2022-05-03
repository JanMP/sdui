import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import SimpleSchema from 'simpl-schema'
import {schemaWithId} from '../common/schemaWithId.coffee'
import {currentUserMustBeInRole} from '../common/roleChecks.coffee'

import _ from 'lodash'

export createTableDataMethods = ({
viewTableRole, editRole, exportTableRole,
sourceName, collection,
useObjectIds,
getRowsPipeline, getRowCountPipeline, getExportPipeline
canEdit, canDelete, canExport
formSchema, makeFormDataFetchMethodRunFkt, makeSubmitMethodRunFkt, makeDeleteMethodRunFkt
enableDeleteForRow, enableEditForRow}) ->
  
  # The Collection might be using ObjectIds instead of String Ids on Mongo
  transformIdToMongo = (id) ->
    if useObjectIds and ((_.isString id) or not id?)
      new Mongo.ObjectID id
    else if not useObjectIds and _.isObject id
      id.toHexString()
    else id

  # MingiMongo always uses String Ids
  transformIdToMiniMongo = (id) ->
    if _.isString id
      id
    else if _.isObject id
      id.toHexString()
    else
      throw new Meteor.Error 'id schould be a String or Object'

  submitMethodRun =
    makeSubmitMethodRunFkt?({collection, transformIdToMongo, transformIdToMiniMongo}) ?
    ({data, id}) ->
      collection.upsert (transformIdToMongo id), $set: data

  formDataFetchMethodRun =
    makeFormDataFetchMethodRunFkt?({collection, transformIdToMongo, transformIdToMiniMongo}) ?
    ({id}) ->
      {(formSchema.clean collection.findOne _id: transformIdToMongo id)..., _id: transformIdToMiniMongo id}

  deleteMethodRun =
    makeDeleteMethodRunFkt?({collection, transformIdToMongo, transformIdToMiniMongo}) ?
    ({id}) ->
      collection.remove _id: transformIdToMongo id
  
  getCount = new ValidatedMethod
    name: "#{sourceName}.getCount"
    validate:
      new SimpleSchema
        search:
          type: String
          optional: true
        query:
          type: Object
          blackbox: true
      .validator()
    run: ({search, query}) ->
      currentUserMustBeInRole viewTableRole
      if Meteor.isServer
        collection.rawCollection()
        .aggregate getRowCountPipeline {search, query}
        .toArray()
        .catch (error) ->
          console.error "#{sourceName}.getCount", error

  getRows = new ValidatedMethod
    name: "#{sourceName}.getRows"
    validate:
      new SimpleSchema
        search:
          type: String
          optional: true
        query:
          type: Object
          blackbox: true
        sort:
          type: Object
          required: false
          blackbox: true
        limit: Number
        skip: Number
      .validator()
    run: ({search, query, sort, limit, skip}) ->
      currentUserMustBeInRole viewTableRole
      if Meteor.isServer
        collection.rawCollection()
        .aggregate getRowsPipeline {search, query, sort, limit, skip},
          allowDiskUse: true
        .toArray()
        .catch (error) ->
          console.error "#{sourceName}.getRows", error

  if canExport
    getExportRows = new ValidatedMethod
      name: "#{sourceName}.getExportRows"
      validate:
        new SimpleSchema
          search:
            type: String
            optional: true
          query:
            type: Object
            blackbox: true
          sort:
            type: Object
            required: false
            blackbox: true
        .validator()
      run: ({search, query, sort}) ->
        currentUserMustBeInRole exportTableRole
        if Meteor.isServer
          collection.rawCollection()
          .aggregate getExportPipeline {search, query, sort},
            allowDiskUse: true
          .toArray()
          .catch (error) ->
            console.error "#{sourceName}.getRows", error

  if canEdit
    submit = new ValidatedMethod
      name: "#{sourceName}.submit"
      validate: (schemaWithId formSchema).validator()
      run: (model) ->
        currentUserMustBeInRole editRole
        submitMethodRun
          id: model._id
          data: _.omit model, '_id'

    fetchEditorData = new ValidatedMethod
      name: "#{sourceName}.fetchEditorData"
      validate:
        new SimpleSchema
          id: String
        .validator()
      run: ({id}) ->
        currentUserMustBeInRole editRole
        if Meteor.isServer
          formDataFetchMethodRun {id}

    #TODO hier bräuchten wir noch validierung für den modifier, ist aber nicht so ganz trivial
    new ValidatedMethod
      name: "#{sourceName}.setValue"
      validate:
        new SimpleSchema
          _id: String
          changeData:
            type: Object
            blackbox: true
        .validator()
      run: ({_id, changeData}) ->
        currentUserMustBeInRole editRole
        collection.update {_id}, $set: changeData

  if canDelete
    new ValidatedMethod
      name: "#{sourceName}.delete"
      validate:
        new SimpleSchema
          id: String
        .validator()
      run: ({id}) ->
        currentUserMustBeInRole editRole
        if Meteor.isServer
          deleteMethodRun {id}

  {getCount, getRows}