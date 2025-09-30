import {Meteor} from 'meteor/meteor'
import {JSONSchemaBridge} from 'uniforms-bridge-json-schema'
import Ajv from 'ajv'
import localize from 'ajv-i18n'
import addErrors from 'ajv-errors'
import addFormats from 'ajv-formats'
import addKeywords from 'ajv-keywords'
import _ from 'lodash'

# TODO write tests

defaultAjvOptions =
  strict: true
  allErrors: true
  useDefaults: false
  coerceTypes: false
  keepErrors: false
  keywords: ['uniforms', 'sdTable', 'sdContent']

export class Schema
  constructor: (@_schema, @options) ->
    try
      if @options? then console.log 'options', @options
      ajvOptions = @options?.ajv ? defaultAjvOptions
      @ajv = new Ajv ajvOptions
      @modelValidator = @options?.modelValidator ? ->
      addKeywords @ajv
      addFormats @ajv
      addErrors @ajv
      @validate = @ajv.compile @_schema
      @validator = (model) =>
        @validate model
        if @validate.errors?.length
          # Localize, but skip custom errorMessage keyword
          localize.de @validate.errors #.filter (e) -> e.keyword isnt 'errorMessage'
          # Map to include field titles in messages for UI
          formatted = @validate.errors
            # .filter (e) -> e.keyword isnt 'errorMessage'
            .map (error) =>
              {node, path} = @_targetFromError error
              title = node?.title ? (error.params?.missingProperty ? @_lastPathToken error.instancePath)
              fieldPath = path.join '.'
              # console.log 'Validation Error', error
              message =
                if title
                  error.message
                  .replace 'muss die Validierung "instanceof" bestehen', 'muss ausgefüllt werden'
                  .replace "Attribut #{fieldPath}", "Feld #{title}"
                else
                  error.message
              # Keep original fields, enhance message and attach helpers
              {
                keyword: error.keyword
                instancePath: error.instancePath
                schemaPath: error.schemaPath
                params: error.params
                message: message
                # Helpful extras that consumers can use
                name: fieldPath
                fieldTitle: title
              }
          details: formatted
        else if (message = @modelValidator model)?
          details: [{
            instancePath: ''
            schemaPath: 'model'
            keyword: 'model'
            params: {}
            message
            name: ''
            fieldTitle: 'Model'
          }]
      @methodValidator = (model) =>
        @validate model
        if @validate.errors?.length
          localize.de @validate.errors.filter (e) -> e.keyword isnt 'errorMessage'
          errors = @validate.errors.filter (e) -> e.keyword isnt 'errorMessage'
          translatedError = errors.map (error) =>
            {node, path} = @_targetFromError error
            title = node?.title ? (error.params?.missingProperty ? @_lastPathToken error.instancePath)
            fieldPath = path.join '.'
            # Use title as the visible name; keep message as type
            name: title ? fieldPath
            type: error.message
          throw new ValidationError translatedError
        else if (message = @modelValidator model)?
          throw new ValidationError [{name: 'model', type: message}]

      @bridge = new JSONSchemaBridge @_schema, @validator
      @firstLevelSchemaKeys = (key for key of @_schema.properties)
    catch error
      throw new Meteor.Error error.message

  # --- helpers to resolve schema node and labels from AJV errors ---

  _splitPath: (instancePath) ->
    # AJV instancePath is a JSON pointer like /a/0/b
    (instancePath ? '').split('/').filter (p) -> Boolean p

  _lastPathToken: (instancePath) ->
    tokens = @_splitPath instancePath
    tokens[tokens.length - 1]

  _targetFromError: (error) ->
    tokens = @_splitPath error.instancePath
    node = @_schema
    path = []

    for t in tokens
      # Skip array indices
      continue if /^\d+$/.test t
      # Traverse arrays
      if node?.type is 'array' and node?.items?
        node = node.items
      # Traverse object properties
      if node?.properties?[t]
        node = node.properties[t]
        path.push t
      else if node?.items?.properties?[t]
        node = node.items.properties[t]
        path.push t

    # Required errors report the parent path and provide the missing property
    if error.keyword is 'required'
      missing = error.params?.missingProperty
      if node?.properties?[missing]
        node = node.properties[missing]
      else if node?.items?.properties?[missing]
        node = node.items.properties[missing]
      path.push missing if missing?

    {node, path}

  idType =
    oneOf: [
      type: 'string'
    , type: 'object'
    ]

  # TODO add handling of required fields
  addProperty: (property) ->
    s = {@_schema...}
    s.properties = {s.properties..., property...}
    new Schema s, @options

  withId: -> @addProperty '_id': {title: 'ID', idType...}

  # TODO add handling of required fields
  pick: (keys) ->
    s = {@_schema...}
    s.properties = _.pick @_schema.properties, keys
    new Schema s, @options

  # TODO add handling of required fields
  omit: (keys) ->
    s = {@_schema...}
    s.properties = _.omit @_schema.properties, keys
    new Schema s, @options

  getQuickTypeForKey: (key) ->
    switch @_schema.properties[key].type
      when 'string' then 'string'
      when 'number' then 'number'
      when 'array'
        switch @_schema.properties[key].items?.type
          when 'string' then 'stringArray'
          when 'number', 'integer' then 'numberArray'
          else 'unhandled'
      else 'unhandled'