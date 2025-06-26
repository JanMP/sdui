# getToolDefinitions.coffee
# Functions to extract and format tool definitions for LangGraph SDK
import {Meteor} from 'meteor/meteor'
import {getToolDefinitions, getToolDefinitionsByRole} from './SdMethodRegistry.coffee'

###*
  Extract JSON-Schema from Schema instance
  @param {Schema} schemaInstance - The Schema instance to extract from
  @returns {Object} JSON-Schema object
  ###
export extractJsonSchema = (schemaInstance) ->
  # Your Schema class already contains JSON-Schema in _schema!
  unless schemaInstance?._schema?
    console.warn 'extractJsonSchema: invalid schema instance'
    return {type: 'object', properties: {}}

  schemaInstance._schema

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
        schema = extractJsonSchema(toolDef.schema)

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

###*
  Get tools for a specific session context
  @param {Object} options - Options object
  @param {String} options.sessionId - Session ID for context
  @param {String} options.agentRole - Agent role for filtering
  @param {Object} options.userRoles - User roles for additional filtering
  @returns {Array} Array of applicable tool definitions
  ###
export getToolsForSession = ({sessionId, agentRole, userRoles} = {}) ->
  try
    # Start with role-based filtering
    tools = getToolsForLangGraph(agentRole)

    # Additional filtering could be added here based on:
    # - Session-specific permissions
    # - User-specific tool access
    # - Context-based tool availability

    if Meteor.isDevelopment
      console.log "Tools for session #{sessionId} with role #{agentRole}:", tools.length

    tools
  catch error
    console.error "Error getting tools for session #{sessionId}:", error
    []

###*
  For backward compatibility or debugging - return as JSON string
  @param {String} [roleFilter] - Optional role to filter tools by
  @returns {String} JSON string of tool definitions
  ###
export getToolsAsJson = (roleFilter = null) ->
  try
    tools = getToolsForLangGraph(roleFilter)
    JSON.stringify(tools, null, 2)
  catch error
    console.error 'Error converting tools to JSON:', error
    '[]'

###*
Validate tool definition format
@param {Object} toolDef - Tool definition to validate
@returns {Boolean} True if valid, false otherwise
###
export validateToolDefinition = (toolDef) ->
  return false unless toolDef?
  return false unless toolDef.method_name?
  return false unless toolDef.json_schema?
  return false unless toolDef.role?

  # Validate JSON schema structure
  schema = toolDef.json_schema
  return false unless schema.type?
  return false unless schema.properties?

  true

if Meteor.isDevelopment
  # Export for debugging in development
  global.getToolsForLangGraph = getToolsForLangGraph
  global.extractJsonSchema = extractJsonSchema
  global.validateToolDefinition = validateToolDefinition
