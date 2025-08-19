import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {Schema, SdMethod} from 'meteor/janmp:sdui'


idType =
  oneOf: [
    type: 'string'
  , type: 'object'
  ]

workspaceSchema = new Schema
  type: 'object'
  properties:
    _id: idType
    sourceSourceName: type: 'string'
    sourceId: idType
    createdAt:
      type: 'object'
      instanceof: 'Date'
    updatedAt:
      type: 'object'
      instanceof: 'Date'
    data: type: 'object'

export class SdWorkspaceAPI

  ###*
    @param {Object} options
    @param {String} options.sourceName - Name of the source
    @param {Mongo.Collection} options.collection - Collection to use
    @param {Schema} options.articleGenerationSchema - Schema of the field containing the data
    @param {any} options.viewRole - Role required to view data
    @param {any} options.editRole - Role required to edit data
    @param {any} options.agentRole - Role required for agent operations
    @param {Object} [options.tableDataOptions] - Options for connected TableDataAPI
    ###
  constructor: (@options) ->
    unless (@sourceName = @options.sourceName)?
      throw new Error 'sourceName is required'
    unless (@collection = @options.collection) instanceof Mongo.Collection
      throw new Error 'collection is not set'
    unless (@articleGenerationSchema = @options.articleGenerationSchema) instanceof Schema
      throw new Error 'articleGenerationSchema is required'
    unless (@viewRole = @options.viewRole)?
      throw new Error 'viewRole is required'
    unless ( @editRole = @options.editRole)?
      throw new Error 'editRole is required'
    unless (@agentRole = @options.agentRole)?
      throw new Error 'agentRole is required'
    @tableDataOptions = @options.tableDataOptions

    @createMethods()
    @createPublications()

  ###*
    Create the contents of a new workspace item.
    Overwrite this method to customize the initial content.
    @return {Object}
    ###
  setupNewItem: -> {}

  ###*
    Create a new workspace item from a table row.
    Defaults to (row) -> row.rawOutput to work with the Redakteur API.
    Overwrite this method to use with table rows other than Redakteur articles.
    @param {Object} row - The document to create the workspace from
    @return {Object} - The document to insert into the workspace collection
    ###
  documentFromRow: (row) -> row.rawOutput

  createMethods: ->
    @_newWorkSpace = new SdMethod
      name: "#{@sourceName}.newWorkspace"
      schema: new Schema {}
      role: @editRole
      agentRole: @agentRole
      run: =>
        newItem = @setupNewItem()
        @collection.insertAsync newItem

    @_newWorkspaceFromDocument = new SdMethod
      name: "#{@sourceName}.newWorkspaceFromDocument"
      schema:
        new Schema
          type: 'object'
          properties:
            document:
              description: 'Document to create a workspace from'
              type: 'object'
            sourceSourceName:
              description: 'Source name of the document'
              type: 'string'
            sourceId:
              description: 'Id of the row to create a workspace from'
              oneOf: [
                type: 'string'
              , type: 'object'
              ]
          required: ['document']
      role: @editRole
      agentRole: @agentRole
      run: ({document, sourceSourceName, sourceId}) ->
        @collection.insertAsync
          sourceSourceName: sourceSourceName
          sourceId: sourceId
          createdAt: new Date()
          updatedAt: new Date()
          data: document

    if @tableDataOptions
      @_newWorkSpaceFromTableRow = new SdMethod
        name: "#{@sourceName}.newWorkspaceFromTableRow"
        schema:
          new Schema
            type: 'object'
            properties:
              rowId:
                description: 'Id of the row to create a workspace from'
                oneOf: [
                  type: 'string'
                , type: 'object'
                ]
            required: ['rowId']
        role: @editRole
        agentRole: @agentRole
        run: ({rowId}) ->
          row = await @tableDataOptions.collection.findOneAsync _id: rowId
          unless row?
            throw new Meteor.Error "Row with id #{rowId} not found in collection #{@tableDataOptions.collection._name}"
          @collection.insertAsync
            sourceSourceName: @sourceName
            sourceId: rowId
            createdAt: new Date()
            updatedAt: new Date()
            data: @documentFromRow(row)

  createPublications: ->
    # TODO: implement publications

