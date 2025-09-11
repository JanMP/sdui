import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {Schema} from 'meteor/janmp:sdui'
import {currentUserMustBeInRole} from '../common/roleChecks.coffee'
import {SdMethod} from './SdMethod.coffee'

import _ from 'lodash'

export createTableDataMethods = ({
viewTableRole, editRole, addRole, deleteRole, exportTableRole,
sourceName, collection,
useObjectIds,
getRowsPipeline, getExportPipeline
canEdit, canAdd, canDelete, canExport
formSchema, makeFormDataFetchMethodRunFkt, makeSubmitMethodRunFkt, makeDeleteMethodRunFkt
checkDisableDeleteForRow, checkDisableEditForRow
sdai}) ->

  cleanedSourceName = sourceName.replace /\./g, '_'

  # The Collection might be using ObjectIds instead of String Ids on Mongo
  transformIdToMongo = (id) ->
    # return id # this is intentional, this should work without transformIdToMongo
    if useObjectIds and ((_.isString id) or not id?)
      new Mongo.ObjectID id
    else if not useObjectIds and _.isObject id
      id._str
    else id

  # MingiMongo always uses String Ids
  transformIdToMiniMongo = (id) ->
    # return id # this is intentional, this should work without transformIdToMiniMongo
    if _.isString id
      id
    else if _.isObject id
      id.toString()
    else
      throw new Meteor.Error 'id schould be a String or Object'

  submitMethodRun =
    makeSubmitMethodRunFkt?({collection, transformIdToMongo, transformIdToMiniMongo}) ?
    ({data, id}) ->
      collection.upsertAsync (transformIdToMongo id), $set: data

  formDataFetchMethodRun =
    makeFormDataFetchMethodRunFkt?({collection, transformIdToMongo, transformIdToMiniMongo}) ?
    ({id}) ->
      {((await collection.findOneAsync _id: transformIdToMongo id))..., _id: transformIdToMiniMongo id}

  deleteMethodRun =
    makeDeleteMethodRunFkt?({collection, transformIdToMongo, transformIdToMiniMongo}) ?
    ({id}) ->
      collection.removeAsync _id: transformIdToMongo id


  idType =
    oneOf: [
      type: 'string'
    , type: 'object'
    ]

  transformRowIdsToMiniMongo = (rows) ->
    return rows unless useObjectIds
    rows.map (row) ->
      {row..., _id: transformIdToMiniMongo(row._id)}

  getRows = new SdMethod
    name: "#{sourceName}.getRows"
    schema: new Schema
      type: 'object'
      properties:
        search: type: 'string'
        query: type: 'object'
        sort: type: 'object'
        limit: type: 'number'
        skip: type: 'number'
    role: viewTableRole
    run: ({search, query, sort, limit, skip}) ->
      # console.log 'getRows', {search, query, sort, limit, skip}
      return unless Meteor.isServer
      collection.rawCollection()
      .aggregate await getRowsPipeline {search, query, sort, limit, skip},
        allowDiskUse: true
      .toArray()
      .then transformRowIdsToMiniMongo
      .catch (error) ->
        console.error "#{sourceName}.getRows", error

  new SdMethod
    name: "#{sourceName}.getRowsKnn"
    schema: new Schema
      type: 'object'
      properties:
        search:
          type: 'string'
          description: "The query string for the knn search."
        limit:
          type: 'integer'
          description: "The maximum number of results to return (defaults to 5)."
      required: ['search']
    role: viewTableRole
    tool:
      if sdai?.agentRole
        name: "#{cleanedSourceName}_searchKnn"
        agentRole: sdai.agentRole
        postProcess: sdai.toolPostProcess
    run: ({search, limit = 5}) ->
      return unless Meteor.isServer
      console.log "#{sourceName}.getRowsKnn", {search, limit}
      vector = await sdai.embeddingFromContext context: search
      sdai.knnFindDocuments {vector, limit}
      .then (rows) ->
        if rows?.length
          console.log "#{sourceName}.getRowsKnn found #{rows.length} rows"
        else
          console.log "#{sourceName}.getRowsKnn found no rows"
        return rows
      .then transformRowIdsToMiniMongo
      .catch (error) ->
        console.error "#{sourceName}.getRowsKnn", error


  if canExport
    new SdMethod
      name: "#{sourceName}.getExportRows"
      schema: new Schema
        type: 'object'
        properties:
          search: type: 'string'
          query: type: 'object'
          sort: type: 'object'
      role: exportTableRole
      run: ({search, query, sort}) ->
        return unless Meteor.isServer
        collection.rawCollection()
        .aggregate await getExportPipeline {search, query, sort},
          allowDiskUse: true
        .toArray()
        .then (rows) ->
          rows.map (row) ->
            {row..., _id: transformIdToMiniMongo(row._id)}
        .catch (error) ->
          console.error "#{sourceName}.getRows", error


  getRowWithId = ({id}) ->
    _id = transformIdToMongo id
    row = await collection.rawCollection().aggregate(getRowsPipeline query: {_id}).toArray()
    if row?.length isnt 1
      throw new Meteor.Error '[getRowWithId-not-array-length-1]'
    {row[0]..., _id: transformIdToMiniMongo(row[0]._id)}

  editRowMustNotBeDisabled = ({id}) ->
    return unless Meteor.isServer
    return unless checkDisableEditForRow
    row = await getRowWithId {id}
    if row?._disableEditForRow
      throw new Meteor.Error '[editRowMustNotBeDisabled]', 'Editing for this Row is disabled'

  deleteRowMustNotBeDisabled = ({id}) ->
    return unless Meteor.isServer
    return unless checkDisableDeleteForRow
    row = await getRowWithId {id}
    if row?._disableDeleteForRow
      throw new Meteor.Error '[deleteRowMustNotBeDisabled]', 'Deleting this Row is disabled'


  if canEdit or canAdd
    new SdMethod
      name: "#{sourceName}.submit"
      schema: formSchema.withId()
      role: editRole  # Note: This might need logic to switch between editRole and addRole
      run: (model) ->
        # console.log "#{sourceName}.submit", {model}
        if model._id?
          await editRowMustNotBeDisabled id: model._id
        else
          await currentUserMustBeInRole addRole
        return unless Meteor.isServer
        try
          result = await submitMethodRun
            id: model._id
            data: _.omit model, '_id'
          if sdai? then sdai.updateEmbeddingForDocumentWithId id: result.insertedId or model._id
          result
        catch error
          console.error "#{sourceName}.submit", error
          new Meteor.Error '[submit-error]', error.message

    new SdMethod
      name: "#{sourceName}.fetchEditorData"
      schema: new Schema
        type: 'object'
        properties:
          id: idType
        required: ['id']
      role: editRole
      run: ({id}) ->
        # console.log "#{sourceName}.fetchEditorData", {id}
        await editRowMustNotBeDisabled {id}
        if Meteor.isServer
          formDataFetchMethodRun {id}

    #TODO hier bräuchten wir noch validierung für den modifier, ist aber nicht so ganz trivial
    new SdMethod
      name: "#{sourceName}.setValue"
      schema: new Schema
        type: 'object'
        properties:
          _id: idType
          changeData:
            type: 'object'
        required: ['_id', 'changeData']
      role: editRole
      run: ({_id, changeData}) ->
        # console.log "#{sourceName}.setValue", {_id, changeData}
        await editRowMustNotBeDisabled id: _id
        return unless Meteor.isServer
        try
          result = await collection.updateAsync {_id}, $set: changeData
          if sdai? then sdai.updateEmbeddingForDocumentWithId id: _id
          result
        catch error
          console.error "#{sourceName}.setValue", error
          new Meteor.Error '[setValue-error]', error.message

  if canDelete
    new SdMethod
      name: "#{sourceName}.delete"
      schema: new Schema
        type: 'object'
        properties:
          id: idType
        required: ['id']
      role: deleteRole
      run: ({id}) ->
        # console.log "#{sourceName}.delete", {id}
        await deleteRowMustNotBeDisabled {id}
        return unless Meteor.isServer
        deleteMethodRun {id}

  {getRows}