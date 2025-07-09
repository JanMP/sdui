import {Meteor} from 'meteor/meteor'
import {SdMethod} from 'meteor/janmp:sdui'
import {Schema} from 'meteor/janmp:sdui'

if Meteor.isServer
  testSchema = new Schema
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


  new SdMethod
    name: 'testMethod'
    schema: testSchema
    role: 'user'
    tool:
      agentRole: {scope: 'langgraphtest', role: 'agent'}  # Proper object format
    run: (args) ->
      console.log 'TestLangGraphTool called with:', args
      return
        success: true
        message: "Received: #{args.message}"
        count: args.count ? 0
        timestamp: new Date()
