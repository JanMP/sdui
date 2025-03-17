# LangGraphChatBot.coffee (to be added to your sdui package)
import {Meteor} from 'meteor/meteor'
import _ from 'lodash'

export class LangGraphChatBot
  constructor: ({
    settings,
    graphName,
    messageCollection,
    botUserData
  }) ->
    unless settings?
      throw new Meteor.Error 'LangGraphChatBot: settings is required'
    unless graphName?
      throw new Meteor.Error 'LangGraphChatBot: graphName is required'
    unless messageCollection?
      throw new Meteor.Error 'LangGraphChatBot: messageCollection is required'
    unless botUserData?
      throw new Meteor.Error 'LangGraphChatBot: botUserData is required'
    
    @client = new (require('@langchain/langgraph-sdk').Client)(settings)
    @graphName = graphName
    @messageCollection = messageCollection
    @botUserData = botUserData
  
  createMessageStub: ({sessionId, text = '', followMessageId = undefined, followDelay = 1}) ->
    createdAt = if followMessageId?
      followMessage = await @messageCollection.findOneAsync followMessageId
      new Date(followMessage.createdAt.getTime() + followDelay)
    else
      new Date()

    @messageCollection.insertAsync
      userId: @botUserData.id
      sessionId: sessionId
      text: text
      chatRole: 'assistant'
      createdAt: createdAt
      workInProgress: true
  
  updateMessageStub: ({messageStubId, text, tools}) ->
    updateObj = {$set: {}}
    updateObj.$set.text = text if text?
    updateObj.$set.tools = tools if tools?
    
    @messageCollection.updateAsync messageStubId, updateObj
  
  finalizeMessageStub: ({messageStubId, text, tools, usage}) ->
    # If there's no real content, just remove the message
    if !text?.trim()
      @messageCollection.removeAsync messageStubId
      console.log "Removed empty message stub:", messageStubId
      return null
    
    # Otherwise finalize it
    updateObj = {$set: {workInProgress: false}}
    updateObj.$set.text = text if text?
    updateObj.$set.tools = tools if tools?
    updateObj.$set.usage = usage if usage?
    
    @messageCollection.updateAsync messageStubId, updateObj
    return messageStubId
  
  createLogMessage: ({sessionId, text = undefined, toolCall = undefined, error = undefined, usage = undefined}) ->
    @messageCollection.insertAsync
      userId: @botUserData.id
      sessionId: sessionId
      text: text
      toolCall: toolCall
      error: if error? then "#{error}" else undefined
      chatRole: 'log'
      createdAt: new Date()
      workInProgress: false
      usage: usage
  
  buildContext: ({sessionId, limit = 15}) ->
    query =
      sessionId: sessionId
      chatRole: {$ne: 'log'}
      workInProgress: {$ne: true}
    
    history = _(await @messageCollection.find(query, {sort: {createdAt: -1}, limit: limit}).fetchAsync())
      .reverse()
      .value()
    
    messages = []
    
    # Add history messages
    for msg in history
      switch msg.chatRole
        when 'user'
          messages.push {role: 'user', content: msg.text}
        when 'assistant'
          # Skip assistant messages with empty content
          continue if !msg.text?.trim()
          
          assistantMsg = {role: 'assistant', content: msg.text}
          if msg.tools?.length
            assistantMsg.tool_calls = msg.tools
          messages.push assistantMsg
        when 'function'
          messages.push {
            role: 'tool'
            content: msg.text
            tool_call_id: msg.tool_id
          }
    
    return messages
    
  processStream: (response, messageStubId) ->
    content = ''
    tools = null
    
    # Process each chunk from the stream
    try
      for await chunk from response
        if chunk?.data?[0]?.content?[0]?.text?
          # Replace content with the latest full version
          content = chunk.data[0].content[0].text
          
          # Update the message stub with the latest content
          @updateMessageStub {messageStubId, text: content}
        
        # Check for tool calls
        if chunk?.data?[0]?.tool_calls?.length
          tools = chunk.data[0].tool_calls
      
      # Return final results
      return {content, tools}
    catch error
      console.error "Stream handling error:", error
      throw error
  
  call: ({sessionId, messageStubId}) ->
    try
      context = await @buildContext {sessionId}
      
      console.log "Running LangGraph with context:", JSON.stringify(context, null, 2)
      
      response = @client.runs.stream null, @graphName,
        input:
          messages: context
        streamMode: "messages"
      
      {content, tools: toolCalls} = await @processStream response, messageStubId
      
      # Finalize or remove the message based on content
      finalMessageId = await @finalizeMessageStub {
        messageStubId, 
        text: content,
        tools: toolCalls,
        usage: {
          model: "langgraph-agent"
        }
      }
      
      # If the message was removed due to empty content, just return
      return finalMessageId unless finalMessageId
      
      # Handle tool calls if they exist
      if toolCalls?.length
        console.log "Processing tool calls:", JSON.stringify(toolCalls)
        
        await Promise.allSettled toolCalls.map (tc) =>
          return unless tc.id?
          
          # Record the tool call in our history
          toolMessage = await @messageCollection.findOneAsync messageStubId
          toolResultDate = new Date(toolMessage.createdAt.getTime() + 1)
          
          args = if typeof tc.args == 'string'
            try
              JSON.parse(tc.args) 
            catch
              tc.args
          else
            tc.args
            
          functionName = tc.name ? tc.function?.name
          console.log "Recording tool call:", functionName
            
          await @messageCollection.insertAsync
            userId: @botUserData.id
            sessionId: sessionId
            chatRole: 'function'
            createdAt: toolResultDate
            workInProgress: false
            text: "Tool result handled by LangGraph Agent"
            tool_id: tc.id
            args: args
            function_name: functionName
        
        # Create a new message for the assistant's response to the function call
        newMessageId = await @createMessageStub {
          sessionId
          text: '...'
          followMessageId: messageStubId
          followDelay: 2
        }
        
        # Call the agent again with the updated context
        return @call {sessionId, messageStubId: newMessageId}
      
      return finalMessageId
    catch error
      console.error "LangGraphChatBot error:", error
      await @createLogMessage {sessionId, error: error}
      throw error