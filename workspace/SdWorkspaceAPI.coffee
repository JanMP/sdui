import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {Schema, SdMethod} from 'meteor/janmp:sdui'

export class SdWorkspaceAPI

  ###*
    @param {Object} options
    @param {String} options.sourceName - Name of the source
    @param {Mongo.Collection} options.collection - Collection to use
    @param {Schema} options.sourceSchema - Schema of the source
    @param {Schema} [options.formSchema] - Schema for forms, defaults to sourceSchema
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
    unless (@sourceSchema = @options.sourceSchema)?
      throw new Error 'sourceSchema is required'
    @formSchema = @options.formSchema ? @sourceSchema
    unless (@viewRole = @options.viewRole)?
      throw new Error 'viewRole is required'
    unless ( @editRole = @options.editRole)?
      throw new Error 'editRole is required'
    unless (@agentRole = @options.agentRole)?
      throw new Error 'agentRole is required'
    @tableDataOptions = @options.tableDataOptions

    @_newWorkSpace = new SdMethod
      name: "#{@sourceName}.newWorkspace"
      schema: {}
      role: @editRole
      agentRole: @agentRole
      run: =>
        console.log "Creating new workspace for #{@sourceName}"

