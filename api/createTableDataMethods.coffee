import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {Schema} from 'meteor/janmp:sdui'
import {currentUserMustBeInRole} from '../common/roleChecks.coffee'

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

  getRows = new ValidatedMethod
    name: "#{sourceName}.getRows"
    validate:
      new Schema
        type: 'object'
        properties:
          search: type: 'string'
          query: type: 'object'
          sort: type: 'object'
          limit: type: 'number'
          skip: type: 'number'
      .methodValidator
    run: ({search, query, sort, limit, skip}) ->
      # console.log 'getRows', {search, query, sort, limit, skip}
      await currentUserMustBeInRole viewTableRole
      return unless Meteor.isServer
      collection.rawCollection()
      .aggregate await getRowsPipeline {search, query, sort, limit, skip},
        allowDiskUse: true
      .toArray()
      .then (rows) ->
        rows.map (row) ->
          {row..., _id: transformIdToMiniMongo(row._id)}
      .catch (error) ->
        console.error "#{sourceName}.getRows", error


  if canExport
    new ValidatedMethod
      name: "#{sourceName}.getExportRows"
      validate:
        new Schema
          type: 'object'
          properties:
            search: type: 'string'
            query: type: 'object'
            sort: type: 'object'
        .methodValidator
      run: ({search, query, sort}) ->
        await currentUserMustBeInRole exportTableRole
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
    new ValidatedMethod
      name: "#{sourceName}.submit"
      validate: formSchema.withId().methodValidator
      run: (model) ->
        # console.log "#{sourceName}.submit", {model}
        if model._id?
          await currentUserMustBeInRole editRole
          await editRowMustNotBeDisabled id: model._id
        else
          await currentUserMustBeInRole addRole
        return unless Meteor.isServer
        submitMethodRun
          id: model._id
          data: _.omit model, '_id'

    new ValidatedMethod
      name: "#{sourceName}.fetchEditorData"
      validate:
        new Schema
          type: 'object'
          properties:
            id: idType
          required: ['id']
        .methodValidator
      run: ({id}) ->
        # console.log "#{sourceName}.fetchEditorData", {id}
        await currentUserMustBeInRole editRole
        await editRowMustNotBeDisabled {id}
        if Meteor.isServer
          formDataFetchMethodRun {id}

    #TODO hier bräuchten wir noch validierung für den modifier, ist aber nicht so ganz trivial
    new ValidatedMethod
      name: "#{sourceName}.setValue"
      validate:
        new Schema
          type: 'object'
          properties:
            _id: idType
            changeData:
              type: 'object'
          required: ['_id', 'changeData']
        .methodValidator
      run: ({_id, changeData}) ->
        # console.log "#{sourceName}.setValue", {_id, changeData}
        await currentUserMustBeInRole editRole
        await editRowMustNotBeDisabled id: _id
        return unless Meteor.isServer
        await collection.updateAsync {_id}, $set: changeData

  if canDelete
    new ValidatedMethod
      name: "#{sourceName}.delete"
      validate:
        new Schema
          type: 'object'
          properties:
            id: idType
          required: ['id']
        .methodValidator
      run: ({id}) ->
        # console.log "#{sourceName}.delete", {id}
        await currentUserMustBeInRole deleteRole
        await deleteRowMustNotBeDisabled {id}
        return unless Meteor.isServer
        deleteMethodRun {id}

  {getRows}