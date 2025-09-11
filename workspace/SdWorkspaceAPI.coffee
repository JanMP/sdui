import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {Schema, SdMethod} from 'meteor/janmp:sdui'


idType =
  oneOf: [
    type: 'string'
  , type: 'object'
  ]


export class WorkspaceDataHandler
  ###*
    @param {Object} options
    @param {SdWorkspaceAPI} options.api - Instance of SdWorkspaceAPI
    ###
  constructor: (@options) ->
    @api = @options.api
    @id = null
    @document = null

  newDocument: ->
    @id = await @api.newDocumentMethod.call()
    @fetchDocument()

  loadDocument: ({id}) ->
    @id = id
    await @api.loadDocumentMethod.call sourceId: id
    @fetchDocument()

  fetchDocument: ->
    unless @id
      throw new Meteor.Error 'Workspace document not loaded'
    @document= await @api.fetchDocumentMethod.call id: @id
    console.log "Fetched workspace document", @document
    @document

  setDocument: (data) =>
    console.log this
    unless @id
      throw new Meteor.Error 'Workspace document not loaded'
    unless @document?.data
      throw new Meteor.Error 'Workspace document has no data'
    await @api.setDocumentMethod.call id: @id, data: data


export class SdWorkspaceAPI

  ###*
    @param {Object} options
    @param {Object} [options.sourceDataOptions] - Options of connected TableDataAPI
    ###
  constructor: (@options) ->
    @sourceDataOptions = @options.sourceDataOptions

    @sourceSourceName = @sourceDataOptions.sourceName
    @sourceName = "#{@sourceSourceName}.workspace"
    @publicationName = "#{@sourceName}.forId"
    @sourceCollection = @sourceDataOptions.collection

    @dataSchema = @sourceDataOptions.formSchema

    @viewRole = @sourceDataOptions.viewTableRole
    @editRole = @sourceDataOptions.editRole
    @agentRole = @sourceDataOptions.agentRole

    @collection = new Mongo.Collection "#{@sourceDataOptions.collection._name}.workspace"

    @workspaceSchema = new Schema
      type: 'object'
      properties:
        _id: idType
        sourceId: idType
        createdAt:
          type: 'object'
          instanceof: 'Date'
        updatedAt:
          type: 'object'
          instanceof: 'Date'
        data: @dataSchema._schema

    @createMethods()
    @createPublications()


  ###*
    Create the contents of a new workspace item.
    Overwrite this method to customize the initial content.
    @return {Object}
    ###
  setupNewItem: ->
    headline: 'New Workspace Document'
    content: 'enter stuff here'

  newDocument: =>
    return unless Meteor.isServer
    console.log 'Creating new workspace document'
    await @collection.insertAsync
      createdAt: new Date()
      updatedAt: new Date()
      data: await @setupNewItem()

  loadDocument: ({sourceId}) =>
    return unless Meteor.isServer
    document = await @sourceCollection.findOneAsync(_id: sourceId)
    console.log "Loading source document #{sourceId} into workspace", document
    @collection.insertAsync
      sourceId: sourceId
      createdAt: new Date()
      updatedAt: new Date()
      data: document

  fetchDocument: ({id}) =>
    return unless Meteor.isServer
    @collection.findOneAsync sourceId: id

  setDocument: ({id, data}) =>
    return unless Meteor.isServer
    await @collection.updateAsync
      _id: id
    ,
      $set:
        data: data
        updatedAt: new Date()

  createMethods: ->
    @newDocumentMethod = new SdMethod
      name: "#{@sourceName}.newDocument"
      schema: new Schema {}
      role: @editRole
      agentRole: @agentRole
      run: @newDocument

    @loadDocumentMethod = new SdMethod
      name: "#{@sourceName}.loadDocument"
      schema:
        new Schema
          type: 'object'
          properties:
            sourceId:
              description: 'Id of the row to create a workspace document from'
              oneOf: [
                type: 'string'
              , type: 'object'
              ]
          required: ['sourceId']
      role: @viewRole
      run: @loadDocument

    @fetchDocumentMethod = new SdMethod
      name: "#{@sourceName}.fetchDocument"
      schema:
        new Schema
          type: 'object'
          properties:
            id:
              description: 'Id of the workspace document to fetch'
              oneOf: [
                type: 'string'
              , type: 'object'
              ]
          required: ['id']
      role: @viewRole
      run: @fetchDocument

    @setDocumentMethod = new SdMethod
      name: "#{@sourceName}.setDocument"
      schema:
        new Schema
          type: 'object'
          properties:
            id:
              description: 'Id of the workspace document to update'
              oneOf: [
                type: 'string'
              , type: 'object'
              ]
            data: @dataSchema._schema
          required: ['id', 'data']
      role: @editRole
      agentRole: @agentRole
      run: @setDocument

  createPublications: ->
    return unless Meteor.isServer
    collection = @collection
    Meteor.publish @publicationName, ({id}) ->
      return @ready() unless id?
      collection.find _id: id
