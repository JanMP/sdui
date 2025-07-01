# SdMethodRegistry.coffee
# Central registry for all SdMethod instances with tool configurations

import {Meteor} from 'meteor/meteor'

# Global registry to track SdMethod instances
export SdMethodRegistry = new Map()

###*
Registration function called by SdMethod constructor
@param {Object} sdMethodInstance - The SdMethod instance to register
###
export registerSdMethod = (sdMethodInstance) ->
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

    SdMethodRegistry.set sdMethodInstance.name, registryEntry

    if Meteor.isDevelopment
      console.log "SdMethod registered as tool: #{sdMethodInstance.name} -> #{sdMethodInstance.toolName}"

###*
Get all method definitions that have tool configurations
@returns {Array} Array of tool definition objects
###
export getToolDefinitions = ->
  Array.from(SdMethodRegistry.values())

###*
Get a specific tool definition by method name
@param {String} methodName - The name of the method
@returns {Object|undefined} Tool definition or undefined if not found
###
export getToolDefinition = (methodName) ->
  SdMethodRegistry.get(methodName)

###*
Get tool definitions filtered by agent role
@param {String|Object} agentRole - The agent role to filter by
@returns {Array} Array of tool definitions for the specified role
###
export getToolDefinitionsByRole = (agentRole) ->
  Array.from(SdMethodRegistry.values()).filter (method) ->
    # Handle object comparison for roles like {scope: 'langgraphtest', role: 'agent'}
    if typeof method.agentRole is 'object' and typeof agentRole is 'object' and method.agentRole?.role? and agentRole?.role?
      method.agentRole.role is agentRole.role and method.agentRole.scope is agentRole.scope
    else
      # Fallback to reference/string equality
      method.agentRole is agentRole

###*
Get all available agent roles
@returns {Array} Array of unique agent roles
###
export getAvailableAgentRoles = ->
  roles = Array.from(SdMethodRegistry.values()).map((method) -> method.agentRole)
  Array.from(new Set(roles)).filter(Boolean)

###*
Get registry statistics for debugging
@returns {Object} Statistics about registered methods
###
export getRegistryStats = ->
  entries = Array.from(SdMethodRegistry.values())

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
###
export clearRegistry = ->
  SdMethodRegistry.clear()

if Meteor.isDevelopment
  # Export registry for debugging in development
  global.SdMethodRegistry = SdMethodRegistry
  global.getRegistryStats = getRegistryStats
