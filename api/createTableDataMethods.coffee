import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import SimpleSchema from 'simpl-schema'
import {schemaWithId} from '../common/schemaWithId.coffee'
import {currentUserMustBeInRole} from '../common/roleChecks.coffee'

import _ from 'lodash'

export createTableDataMethods = ({
viewTableRole, editRole, addRole, deleteRole, exportTableRole,
sourceName, collection,
useObjectIds,
getRowsPipeline, getRowCountPipeline, getExportPipeline
canEdit, canAdd, canDelete, canExport
formSchema, makeFormDataFetchMethodRunFkt, makeSubmitMethodRunFkt, makeDeleteMethodRunFkt
checkDisableDeleteForRow, checkDisableEditForRow}) ->
  
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
    new ValidatedMethod
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

  getRowWithId = ({id}) ->
    row = await collection.rawCollection().aggregate(getRowsPipeline {query: _id: id}).toArray()
    if row?.length isnt 1
      throw new Meteor.Error '[getRowWithId-not-array-length-1]'
    row[0]
  
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
      validate: (schemaWithId formSchema).validator()
      run: (model) ->
        if model._id?
          currentUserMustBeInRole editRole
        else
          currentUserMustBeInRole addRole
        await editRowMustNotBeDisabled id: model._id
        submitMethodRun
          id: model._id
          data: _.omit model, '_id'

    new ValidatedMethod
      name: "#{sourceName}.fetchEditorData"
      validate:
        new SimpleSchema
          id: String
        .validator()
      run: ({id}) ->
        currentUserMustBeInRole editRole
        await editRowMustNotBeDisabled: {id}
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
        await editRowMustNotBeDisabled id: _id
        collection.update {_id}, $set: changeData

  if canDelete
    new ValidatedMethod
      name: "#{sourceName}.delete"
      validate:
        new SimpleSchema
          id: String
        .validator()
      run: ({id}) ->
        currentUserMustBeInRole deleteRole
        await deleteRowMustNotBeDisabled {id}
        if Meteor.isServer
          deleteMethodRun {id}

  {getCount, getRows}