# getToolDefinitions.coffee
# Functions to extract and format tool definitions for LangGraph SDK
import {Meteor} from 'meteor/meteor'
import {getToolDefinitions, getToolDefinitionsByRole} from './SdMethodRegistry.coffee'


###*
  Get tool definitions formatted for LangGraph SDK
  @param {String} [roleFilter] - Optional role to filter tools by
  @returns {Array} Array of tool definitions in LangGraph format
  ###
export getToolsForLangGraph = (roleFilter = null) ->
  try
    # Get registered tool definitions
    toolDefinitions = if roleFilter?
      getToolDefinitionsByRole roleFilter
    else
      getToolDefinitions()

    # Convert to LangGraph SDK format
    langGraphTools = toolDefinitions.map (toolDef) ->
      try
        schema = toolDef.schema._schema

        # LangGraph tool definition format
        result =
          method_name: toolDef.toolName
          json_schema: schema
          description: schema.description or toolDef.description or "Meteor method: #{toolDef.name}"
          role: toolDef.agentRole

        # Add instruction for role requirements
        if toolDef.agentRole?
          result.instruction = "Role required: #{toolDef.agentRole}"

        result
      catch error
        console.error "Error converting tool definition #{toolDef.name}:", error
        null

    # Filter out any failed conversions
    langGraphTools.filter(Boolean)

  catch error
    console.error 'Error getting tools for LangGraph:', error
    []
