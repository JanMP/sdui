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
      await collection.upsertAsync (transformIdToMongo id), $set: data

  formDataFetchMethodRun =
    makeFormDataFetchMethodRunFkt?({collection, transformIdToMongo, transformIdToMiniMongo}) ?
    ({id}) ->
      {((await collection.findOneAsync _id: transformIdToMongo id))..., _id: transformIdToMiniMongo id}

  deleteMethodRun =
    makeDeleteMethodRunFkt?({collection, transformIdToMongo, transformIdToMiniMongo}) ?
    ({id}) ->
      await collection.removeAsync _id: transformIdToMongo id


  getRows = new ValidatedMethod
    name: "#{sourceName}.getRows"
    validate:
      new Schema
        type: 'object'
        properties:
          search: type: 'string'
          query: type: 'object'
          queryUiObject: type: 'object'
          sort: type: 'object'
          limit: type: 'number'
          skip: type: 'number'
      .validator
    run: ({search, query, queryUiObject, sort, limit, skip}) ->
      # console.log 'getRows', {search, query, queryUiObject, sort, limit, skip}
      await currentUserMustBeInRole viewTableRole
      return unless Meteor.isServer
      collection.rawCollection()
      .aggregate await getRowsPipeline {search, query, queryUiObject, sort, limit, skip},
        allowDiskUse: true
      .toArray()
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
            queryUiObject: type: 'object'
            sort: type: 'object'
        .validator
      run: ({search, query, queryUiObject, sort}) ->
        await currentUserMustBeInRole exportTableRole
        return unless Meteor.isServer
        collection.rawCollection()
        .aggregate await getExportPipeline {search, query, queryUiObject, sort},
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
      validate: formSchema.withId().validator
      run: (model) ->
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
            id: type: 'string'
        .validator
      run: ({id}) ->
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
            _id: type: 'string'
            changeData:
              type: 'object'
        .validator
      run: ({_id, changeData}) ->
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
            id: type: 'string'
        .validator
      run: ({id}) ->
        await currentUserMustBeInRole deleteRole
        await deleteRowMustNotBeDisabled {id}
        return unless Meteor.isServer
        deleteMethodRun {id}

  {getRows}