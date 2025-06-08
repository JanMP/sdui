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
          localize.de @validate.errors.filter (e) -> e.keyword isnt 'errorMessage'
          console.log @validate.errors
          details: @validate.errors
        else if (message = @modelValidator model)?
          details: [{
            instancePath: ''
            schemaPath: 'model'
            keyword: 'model'
            params: {}
            message
          }]
      @methodValidator = (model) =>
        @validate model
        if @validate.errors?.length
          localize.de @validate.errors.filter (e) -> e.keyword isnt 'errorMessage'
          translatedError = @validate.errors.map (error) ->
            name: error.instancePath.replace '/', ''
            type: error.message
          throw new ValidationError translatedError
        else if (message = @modelValidator model)?
          throw new ValidationError [{name: 'model', type: message}]

      @bridge = new JSONSchemaBridge @_schema, @validator
      @firstLevelSchemaKeys = (key for key of @_schema.properties)
    catch error
      throw new Meteor.Error error.message

  idType =
    oneOf: [
      type: 'string'
    , type: 'object'
    ]

  addProperty: (property) ->
    s = {@_schema...}
    s.properties = {s.properties..., property...}
    new Schema s, @options

  withId: -> @addProperty '_id': {title: 'ID', idType...}

  pick: (keys) ->
    s = {@_schema...}
    s.properties = _.pick @_schema.properties, keys
    new Schema s, @options

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