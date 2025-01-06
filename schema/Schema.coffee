import {Meteor} from 'meteor/meteor'
import {JSONSchemaBridge} from 'uniforms-bridge-json-schema'
import Ajv from 'ajv'
import addFormats from 'ajv-formats'
import addKeywords from 'ajv-keywords'
import _ from 'lodash'

# TODO write tests

defaultAjvOptions =
  strict: true
  allErrors: true
  useDefaults: false
  coerceTypes: false
  keywords: ['uniforms', 'sdTable', 'sdContent']

export class Schema
  constructor: (@_schema, @options) ->
    try
      if @options? then console.log 'options', @options
      ajvOptions = @options?.ajv ? defaultAjvOptions
      @ajv = new Ajv ajvOptions
      @modelValidator = @options?.modelValidator
      addFormats @ajv
      addKeywords @ajv
      @validate = @ajv.compile @_schema
      @validator = (model) =>
        @validate model
        if @validate.errors?.length
          return details: @validate.errors
        @modelValidator?(model)

      @bridge = new JSONSchemaBridge @_schema, @validator
      @firstLevelSchemaKeys = (key for key of @_schema.properties)
    catch error
      throw new Meteor.Error error.message
  
  addProperty: (property) ->
    s = {@_schema...}
    s.properties = {s.properties..., property...}
    new Schema s, @options
  
  withId: -> @addProperty '_id': type: 'string'
  
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