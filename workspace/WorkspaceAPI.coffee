import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {Schema, SdMethod} from 'meteor/janmp:sdui'


idType =
  oneOf: [
    type: 'string'
  , type: 'object'
  ]


export class WorkspaceAPI

  ###*
    @param {Object} options
    @param {Object} [options.sourceDataOptions] - Options of connected TableDataAPI
    @param {Object} [options.agentRole] - Role to be used for agent actions (like creating new workspace documents)
    ###
  constructor: (@options) ->
    @sourceDataOptions = @options.sourceDataOptions

    unless @sourceDataOptions?
      throw new Error 'no sourceDataOptions given for WorkspaceAPI'

    @agentRole = @options.agentRole
    @agentRole ?= @sourceDataOptions.sdai?.agentRole

    unless @agentRole?
      throw new Error 'no agentRole defined for WorkspaceAPI'

    @sourceSourceName = @sourceDataOptions.sourceName
    @sourceName = "#{@sourceSourceName}.workspace"
    @publicationName = "#{@sourceName}.forId"
    @sourceCollection = @sourceDataOptions.collection

    @dataSchema = @sourceDataOptions.formSchema

    @viewRole = @sourceDataOptions.viewTableRole
    @editRole = @sourceDataOptions.editRole

    @collection = new Mongo.Collection "#{@sourceDataOptions.collection._name}.workspace"

    @workspaceSchema = new Schema
      type: 'object'
      properties:
        documentId: idType
        sessionId: idType
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
  setupNewItem: -> {}

  ###*
    Transform source document to workspace data format.
    Override this method to customize how source documents are loaded into the workspace.
    Default: assumes source document structure matches workspace data schema directly.
    @param {Object} sourceDocument - document from source collection
    @return {Object} - data object for workspace
    ###
  transformSourceToWorkspace: (sourceDocument) ->
    # Default implementation: source document structure matches workspace data schema
    return sourceDocument

  ###*
    Transform workspace data to source document format.
    Override this method to customize how workspace data is saved to source collection.
    Default: assumes workspace data structure matches source collection schema directly.
    @param {Object} workspaceData - data from workspace
    @return {Object} - document object for source collection
    ###
  transformWorkspaceToSource: (workspaceData) ->
    # Default implementation: workspace data structure matches source collection schema
    return workspaceData

  newDocument: ({sessionId}) =>
    return unless Meteor.isServer
    console.log 'Creating new workspace document'

    initialData = await @setupNewItem()

    await @collection.upsertAsync {sessionId},
      sessionId: sessionId
      documentId: null
      createdAt: new Date()
      updatedAt: new Date()
      data: initialData

    # Return the initial data (clean interface for agent)
    return initialData

  loadDocument: ({sessionId, documentId}) =>
    return unless Meteor.isServer
    sourceDocument = await @sourceCollection.findOneAsync _id: documentId
    return unless sourceDocument?

    console.log "Loading source document #{documentId} into workspace", sourceDocument

    # Transform source document to workspace data format using configurable hook
    workspaceData = @transformSourceToWorkspace sourceDocument

    await @collection.upsertAsync {sessionId},
      sessionId: sessionId
      documentId: documentId
      createdAt: new Date()
      updatedAt: new Date()
      data: workspaceData

    # Return the loaded data (clean interface for agent)
    return workspaceData

  saveDocument: ({sessionId}) =>
    return unless Meteor.isServer

    # Fetch the full workspace document (internal structure)
    workspaceDoc = await @collection.findOneAsync {sessionId}
    return unless workspaceDoc?.data?

    # Transform workspace data to source document format using configurable hook
    sourceData = @transformWorkspaceToSource workspaceDoc.data

    if workspaceDoc.documentId?
      # Update existing document in source collection
      await @sourceCollection.updateAsync {_id: workspaceDoc.documentId}, sourceData
      console.log "Updated existing document #{workspaceDoc.documentId} in source collection"
    else
      # Insert new document in source collection
      insertResult = await @sourceCollection.insertAsync sourceData

      # Update workspace with the new document ID
      await @collection.updateAsync {sessionId},
        $set:
          documentId: insertResult.insertedId
          updatedAt: new Date()

      console.log "Inserted new document #{insertResult.insertedId} in source collection"

    # Return success confirmation with current data (clean interface)
    return {
      success: true
      documentId: workspaceDoc.documentId or insertResult?.insertedId
      data: workspaceDoc.data
      message: 'Document saved successfully to source collection'
    }

  fetchDocument: ({sessionId}) =>
    return unless Meteor.isServer
    workspaceDoc = await @collection.findOneAsync {sessionId}
    return unless workspaceDoc?
    # Return only the data part - hide internal workspace structure from agent
    return workspaceDoc.data

  setDocument: ({sessionId, data}) =>
    return unless Meteor.isServer
    # Agent sends document data directly - we handle internal data folder mapping
    # Use upsert to create document if it doesn't exist
    await @collection.upsertAsync {sessionId},
      $set:
        data: data
        updatedAt: new Date()
      $setOnInsert:
        sessionId: sessionId
        documentId: null
        createdAt: new Date()

    # Return the updated document data (clean interface)
    return await @fetchDocument {sessionId}


  ###*
    Path based patching for precise updates, especially inside arrays.

    USAGE:
    Use dotted paths to update specific fields without replacing entire objects/arrays:

    Examples:
      { set: { 'recipe_title': 'New Title', 'recipe_ingredients.0.amount': '2' } }
      { unset: ['old_field', 'recipe_steps.3.temp_note'] }

    Path formats:
    - Simple fields: 'recipe_title', 'recipe_skill'
    - Nested objects: 'recipe_nutritionals.kcal'
    - Array elements: 'recipe_ingredients.0.name' (use existing indices only)
    - Deep nesting: 'recipe_cooking_steps.1.step_ingredients.0.unit'

    BEHAVIOR:
    - Changes are ALWAYS applied to the document first
    - Then validation is performed against the schema
    - If validation fails, changes remain saved but flagged as invalid
    - Response includes current document state and schema guidance for fixes

    Returns structured response with:
    - success: boolean (false = changes saved but need schema compliance fixes)
    - data: current document after your changes were applied
    - validationErrors: detailed issues with paths and expected formats
    - schemaInfo: helpful information about expected data structure
    - message: clear status and next steps

    @param {Object} options
    @param {String|Object} options.sessionId
    @param {Object} [options.set] - key/value map of dotted paths to set
    @param {Array<String>} [options.unset] - array of dotted paths to remove
    ###
  patchDocumentPaths: ({sessionId, set = {}, unset = []}) =>
    return unless Meteor.isServer
    return unless sessionId?
    return unless (Object.keys(set).length + unset.length) > 0

    # Apply the patch updates
    modifier = {}
    if Object.keys(set).length
      modifier.$set = {}
      for key, value of set
        modifier.$set["data.#{key}"] = value
    if unset.length
      modifier.$unset = {}
      for p in unset when typeof p is 'string'
        modifier.$unset["data.#{p}"] = ''

    modifier.$set ?= {}
    modifier.$set.updatedAt = new Date()

    await @collection.updateAsync {sessionId}, modifier

    # Fetch the updated document data (clean interface)
    updatedData = await @fetchDocument {sessionId}
    return {success: false, message: 'Document not found after update'} unless updatedData?

    # Validate the data using the schema
    validationResult = @dataSchema.validator updatedData
    
    if validationResult?.details?.length
      # Validation failed - collect error details
      validationErrors = []
      
      for detail in validationResult.details
        validationErrors.push {
          path: detail.name or detail.instancePath or 'unknown'
          message: detail.message or 'Validation error'
          type: detail.keyword or 'validation'
          fieldTitle: detail.fieldTitle
        }
      
      return {
        success: false
        data: updatedData
        validationErrors: validationErrors
        schemaInfo: @_getSchemaHelp()
        message: "⚠️ IMPORTANT: Your changes were SAVED to the document, but there are #{validationErrors.length} validation error(s) that need to be fixed. The current data (with your changes) is shown below. Use the schemaInfo to understand expected formats and make additional patches to resolve the issues."
      }
    else
      # Validation successful
      return {
        success: true
        data: updatedData
        validationErrors: []
        schemaInfo: @_getSchemaHelp()
        message: '✅ Changes applied successfully! All data is valid and ready to use.'
      }

  ###*
    Generate helpful schema information for agents.
    ###
  _getSchemaHelp: ->
    schemaProps = @dataSchema._schema.properties or {}
    help = {
      pathExamples: {
        'Simple field': 'recipe_title'
        'Nested object': 'recipe_nutritionals.kcal'
        'Array item': 'recipe_ingredients.0.name'
        'Deep nested': 'recipe_cooking_steps.1.step_ingredients.0.unit'
      }
      commonFields: {}
      enumFields: {}
    }

    # Extract common fields and their types
    for fieldName, fieldDef of schemaProps
      fieldType = fieldDef.type or 'unknown'
      help.commonFields[fieldName] = fieldType

      # Check for enum values
      if fieldDef.enum?
        help.enumFields[fieldName] = fieldDef.enum

      # Check nested arrays/objects for enums
      if fieldType is 'array' and fieldDef.items?
        if fieldDef.items.enum?
          help.enumFields["#{fieldName} (array items)"] = fieldDef.items.enum
        else if fieldDef.items.properties?
          for nestedName, nestedDef of fieldDef.items.properties
            if nestedDef.enum?
              help.enumFields["#{fieldName}.*.#{nestedName}"] = nestedDef.enum

    return help

  ###*
    Alias for updateDocumentFields to have a shorter tool name.
    ###
  patchDocument: (opts) => @updateDocumentFields opts

  setupWorkspace: ({sessionId, documentId}) =>
    return unless Meteor.isServer
    return if (await @fetchDocument {sessionId})?
    if not documentId? or documentId is 'new'
      await @newDocument sessionId: sessionId
    else
      await @loadDocument sessionId: sessionId, documentId: documentId


  createMethods: ->
    console.log "Creating workspace methods for #{@sourceName}"
    console.log "viewRole", @viewRole
    console.log "editRole", @editRole
    console.log "agentRole", @agentRole
    console.log "dataSchema", @dataSchema._schema

    cleanedSourceName = @sourceName.replace /\./g, '_'
    @newDocumentMethod = new SdMethod
      name: "#{@sourceName}.newDocument"
      schema:
        new Schema
          type: 'object'
          properties:
            sessionId: idType
          required: ['sessionId']
      role: @viewRole
      # tool:
      #   name: "#{cleanedSourceName}_newDocument"
      #   agentRole: @agentRole
      run: @newDocument

    @loadDocumentMethod = new SdMethod
      name: "#{@sourceName}.loadDocument"
      schema:
        new Schema
          type: 'object'
          properties:
            sessionId: idType
            documentId:
              description: 'Id of the row to create a workspace document from'
              oneOf: [
                type: 'string'
              , type: 'object'
              ]
          required: ['sessionId', 'documentId']
      role: @viewRole
      # tool:
      #   agentRole: @agentRole
      run: @loadDocument

    @fetchDocumentMethod = new SdMethod
      name: "#{@sourceName}.fetchDocument"
      schema:
        new Schema
          type: 'object'
          properties:
            sessionId:
              description: 'sessionId of the chat/agent using this workspace'
              oneOf: [
                type: 'string'
              , type: 'object'
              ]
          required: ['sessionId']
      role: @viewRole
      tool:
        name: "#{cleanedSourceName}_fetchDocument"
        agentRole: @agentRole
        sessionIdField: 'sessionId'
      run: @fetchDocument

    @setDocumentMethod = new SdMethod
      name: "#{@sourceName}.setDocument"
      schema:
        new Schema
          type: 'object'
          properties:
            sessionId:
              description: 'sessionId of the chat/agent using this workspace'
              oneOf: [
                type: 'string'
              , type: 'object'
              ]
            data: @dataSchema._schema
          required: ['sessionId', 'data']
      role: @agentRole
      tool:
        name: "#{cleanedSourceName}_setDocument"
        agentRole: @agentRole
        sessionIdField: 'sessionId'
      run: @setDocument


    # Path-based partial update method (fine grained)
    @patchDocumentPathsMethod = new SdMethod
      name: "#{@sourceName}.patchDocumentPaths"
      schema:
        new Schema
          type: 'object'
          properties:
            sessionId: idType
            set:
              description: 'Map of dotted paths to values'
              type: 'object'
            unset:
              description: 'Array of dotted paths to remove'
              type: 'array'
              items: type: 'string'
          required: ['sessionId']
      role: @agentRole
      tool:
        name: "#{cleanedSourceName}_patchPaths"
        agentRole: @agentRole
        sessionIdField: 'sessionId'
      run: @patchDocumentPaths

    @saveDocumentMethod = new SdMethod
      name: "#{@sourceName}.saveDocument"
      schema:
        new Schema
          type: 'object'
          properties:
            sessionId:
              description: 'sessionId of the chat/agent using this workspace'
              oneOf: [
                type: 'string'
              , type: 'object'
              ]
          required: ['sessionId']
      role: @sourceDataOptions.editRole
      run: @saveDocument

    @setupWorkspaceMethod = new SdMethod
      name: "#{@sourceName}.setupWorkspace"
      schema:
        new Schema
          type: 'object'
          properties:
            sessionId:
              description: 'sessionId of the chat/agent using this workspace'
              oneOf: [
                type: 'string'
              , type: 'object'
              ]
            documentId:
              description: 'Id of the row to create a workspace document from, or "new" to create a new document'
              oneOf: [
                type: 'string'
              , type: 'object'
              ]
          required: ['sessionId']
      role: @sourceDataOptions.viewTableRole
      run: @setupWorkspace

  createPublications: ->
    return unless Meteor.isServer
    collection = @collection
    Meteor.publish @publicationName, ({sessionId}) ->
      return @ready() unless sessionId?
      collection.find {sessionId}
