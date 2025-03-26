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


  updateMessageStub: ({messageStubId, text, tools = undefined}) ->
    @messageCollection.updateAsync messageStubId,
      $set:
        text: text
        tools: tools


  finalizeMessageStub: ({messageStubId, text, tools}) ->
    @messageCollection.updateAsync messageStubId,
      $set:
        text: text
        tools: tools
        workInProgress: false
  
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
  

  processStream: ({response, messageStubId}) ->
    content = ''
    
    # Process each chunk from the stream
    try
      for await chunk from response
        if chunk?.data?[0]?.content?[0]?.text?
          # Replace content with the latest full version
          content = chunk.data[0].content[0].text
          
          # Update the message stub with the latest content
          @updateMessageStub {messageStubId, text: content}
        
        # Check for tool calls
        # if chunk?.data?[0]?.tool_calls?.length
        #   tools = chunk.data[0].tool_calls
      
      # Return final results
      return {content, tools}
    catch error
      console.error "Stream handling error:", error
      throw error


  call: ({sessionId, messageStubId, text}) ->
    try
      
      console.log "Running LangGraph with text:", text
      
      response = await @client.runs.stream null, @graphName,
        input:
          messages: text
        streamMode: "messages"

      
      {content, tools: toolCalls} = await @processStream response, messageStubId
      
      # Finalize and return the message id
      await @finalizeMessageStub {
        messageStubId
        text: content
        tools: toolCalls
      }

    catch error
      console.error "LangGraphChatBot error:", error
      await @createLogMessage {sessionId, error: error}
      throw error