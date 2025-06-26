# test-registry.coffee
# Simple test to verify SdMethodRegistry functionality

import {Meteor} from 'meteor/meteor'
import {SdMethod} from 'meteor/janmp:sdui'
import {Schema} from 'meteor/janmp:sdui'
import {getToolsForLangGraph, getRegistryStats} from 'meteor/janmp:sdui'

if Meteor.isServer
  # Test Schema
  TestSchema = new Schema
    type: 'object'
    properties:
      message:
        type: 'string'
        title: 'Test Message'
        description: 'A test message to send'
      count:
        type: 'number'
        title: 'Count'
        description: 'A number for testing'
        minimum: 0
    required: ['message']
    description: 'Test schema for LangGraph tool integration'

  # Test SdMethod with tool configuration
  testMethod = new SdMethod
    name: 'testLangGraphTool'
    schema: TestSchema
    role: 'user'
    tool:
      name: 'testLangGraphTool_agent'  # Different from method name, LangGraph-compliant
      agentRole: 'langgraphtest:agent'  # Use string format for scoped role
    run: (args) ->
      console.log 'TestLangGraphTool called with:', args
      return {
        success: true
        message: "Received: #{args.message}"
        count: args.count ? 0
        timestamp: new Date()
      }

  # Log registry stats on startup
  Meteor.startup ->
    stats = getRegistryStats()
    console.log 'SdMethodRegistry startup stats:', stats

    if stats.totalMethods > 0
      console.log 'Available tools for LangGraph:'
      tools = getToolsForLangGraph()
      for tool in tools
        console.log "  - #{tool.method_name} (role: #{tool.role})"
    else
      console.log 'No tools registered yet'
