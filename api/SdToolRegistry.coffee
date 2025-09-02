import {Meteor} from 'meteor/meteor'

###*
  Central registry class for managing SdMethod instances with tool configurations

  This class provides a centralized way to register, retrieve, and manage
  SdMethod instances that have tool configurations. It maintains a registry
  of methods and provides various utility functions for filtering and accessing them.

  @example
  # Using the default instance
  registry = new SdMethodRegistry()
  registry.registerSdMethod(sdMethodInstance)
  tools = registry.getToolDefinitions()

  # Or use the exported instance
  defaultRegistry.registerSdMethod(sdMethodInstance)
  ###
export class SdMethodRegistry

  ###*
    Constructor for SdMethodRegistry

    Initializes a new Map to store registered SdMethod instances.
    ###
  constructor: ->
    @registry = new Map()

  ###*
    Registration function called by SdMethod constructor

    @param {Object} sdMethodInstance - The SdMethod instance to register
    @returns {void}
    ###
  register: (sdMethodInstance) ->
    unless sdMethodInstance.name?
      console.warn 'SdMethod registration: instance missing name'
      return

    # Only register if it has tool configuration
    if sdMethodInstance.toolName?
      registryEntry =
        name: sdMethodInstance.name
        toolName: sdMethodInstance.toolName
        schema: sdMethodInstance.schema
        role: sdMethodInstance.role
        agentRole: sdMethodInstance.agentRole
        description: sdMethodInstance.schema?._schema?.description
        method: sdMethodInstance  # Keep reference to original method

      @registry.set sdMethodInstance.name, registryEntry

      if Meteor.isDevelopment
        console.log "SdMethod registered as tool: #{sdMethodInstance.name} -> #{sdMethodInstance.toolName}"

  ###*
    Get all method definitions that have tool configurations
    @returns {Array} Array of tool definition objects
    ###
  getToolDefinitions: ->
    Array.from(@registry.values())

  ###*
    Get a specific tool definition by method name
    @param {String} methodName - The name of the method
    @returns {Object|undefined} Tool definition or undefined if not found
    ###
  getToolDefinition: (methodName) ->
    @registry.get(methodName)

  ###*
    Get tool definitions filtered by agent role
    @param {String|Object} agentRole - The agent role to filter by
    @returns {Array} Array of tool definitions for the specified role
    ###
  getToolDefinitionsByRole: (agentRole) ->
    console.log "getToolDefinitionsByRole called with:", agentRole
    Array.from(@registry.values())
    .filter (method) ->
      # Handle object comparison for roles like {scope: 'langgraphtest', role: 'agent'}
      if typeof method.agentRole is 'object' and typeof agentRole is 'object'
        method.agentRole.role is agentRole.role and method.agentRole.scope is agentRole.scope
      else
        # Fallback to reference/string equality
        method.agentRole is agentRole
    .map (method) ->
      method_name: method.toolName
      json_schema: method.schema._schema
      description: method.description or method.schema._schema?.description or "Meteor method: #{method.name}"
      role: method.agentRole
      instruction: if method.agentRole? then "Role required: #{JSON.stringify method.agentRole}"

  ###*
    Get registry statistics for debugging
    @returns {Object} Statistics about registered methods
    ###
  getStats: ->
    entries = Array.from(@registry.values())

    stats =
      totalMethods: entries.length
      byRole: {}
      methodNames: entries.map((entry) -> entry.name)
      toolNames: entries.map((entry) -> entry.toolName)

    # Count by role
    for entry in entries
      role = entry.agentRole ? 'unknown'
      stats.byRole[role] = (stats.byRole[role] ? 0) + 1

    stats

  ###*
    Clear the registry (mainly for testing)
    @returns {void}
    ###
  clearRegistry: ->
    @registry.clear()

# Export both the class and a default instance
export defaultSdMethodRegistry = new SdMethodRegistry()
