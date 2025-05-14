# LangGraphChatBot.coffee (to be added to your sdui package)
import {Meteor} from 'meteor/meteor'
import _ from 'lodash'
import LangGraphSDK from '@langchain/langgraph-sdk'

logReturn = (x) ->
  console.log x
  x

export class LangGraphChatBot
  
  constructor: ({
    settings,
    graphName,
    messageCollection,
    sessionListCollection,
    metaDataCollection,
    botUserData
  }) ->
    unless settings?
      throw new Meteor.Error 'LangGraphChatBot: settings is required'
    unless graphName?
      throw new Meteor.Error 'LangGraphChatBot: graphName is required'
    unless messageCollection?
      throw new Meteor.Error 'LangGraphChatBot: messageCollection is required'
    unless sessionListCollection?
      throw new Meteor.Error 'LangGraphChatBot: sessionCollection is required'
    unless botUserData?
      throw new Meteor.Error 'LangGraphChatBot: botUserData is required'
    
    @client = new (LangGraphSDK.Client)(settings)
    @graphName = graphName
    @messageCollection = messageCollection
    @metaDataCollection = metaDataCollection
    @sessionCollection = sessionListCollection
    @botUserData = botUserData


  upsertThreadId: ({sessionId}) ->
    savedThreadId = (await @sessionCollection.findOneAsync sessionId)?.threadId
    threadId = savedThreadId ? (await @client.threads.create())?.thread_id
    if not savedThreadId?
      @sessionCollection.updateAsync sessionId,
        $set:
          threadId: threadId
    threadId


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

  ###*
    @param {Object} options
    @param {String} options.sessionId
    @param {String} options.itemId
    @param {Object} options.metadata
    @returns {Promise<void>}
    ###
  createMetaDataItem: ({sessionId, itemId, metadata}) ->
    console.log {sessionId, itemId, metadata}
    @metaDataCollection.upsertAsync {sessionId, itemId},
      sessionId: sessionId
      itemId: itemId
      metadata: metadata
      createdAt: new Date()

  updateMetaDataItem: ({sessionId, itemId, data}) ->
    @metaDataCollection.updateAsync {sessionId, itemId},
      $set:
        data: data
        updatedAt: new Date()


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

  ###*
    @param {Object} options
    @param {String} options.sessionId
    @param {String} [options.text]
    @param {Object} [options.toolCall]
    @param {Object} [options.error]
    @param {Object} [options.usage]
    @returns {Promise<void>}
    ###
  createLogMessage: ({sessionId, text, toolCall, error, usage}) ->
    @messageCollection.insertAsync
      userId: @botUserData.id
      sessionId: sessionId
      text: text
      toolCall: toolCall
      error: error
      chatRole: 'log'
      createdAt: new Date()
      workInProgress: false
      usage: usage
  

  processStream: ({sessionId, response, messageStubId}) ->
    content = ''
    streamMetaData = {}

    # Process each chunk from the response
    try
      for await chunk from response
        switch chunk.event
          when "messages/metadata"
            # console.log "#{"#".repeat 20} metadata #{"#".repeat 20}"
            # console.log JSON.stringify chunk, null, 2
            streamMetaData = {streamMetaData..., chunk.data...}
            for itemId, {metadata} of chunk.data
              unless metadata?.langgraph_node is 'final_response'
                await @createMetaDataItem {sessionId, itemId, metadata}
          when "messages/partial", "messages/complete"
            for dataItem in chunk.data
              {id, content} = dataItem
              metadata = streamMetaData[id]?.metadata
              # console.log dataItem
              if metadata?.langgraph_node is 'final_response'
                await @updateMessageStub {messageStubId, text: content}
              else
                # if chunk.event is 'messages/complete'
                #   console.log "#{"#".repeat 20} chunk #{"#".repeat 20}"
                #   console.log JSON.stringify {chunk, id, metadata}, null, 2
                await @updateMetaDataItem {sessionId, itemId: id, data: dataItem}
          when "error"
            console.error "Error in stream:", chunk
            await @createLogMessage {sessionId, text: "Error in stream", error: chunk.data}
          else
            unless Meteor.isDevelopment
              console.log "LangGraph Stream: unhandled event type:", chunk.event
            # console.log "#{"#".repeat 20} unknown chunk #{"#".repeat 20}"
            # console.log JSON.stringify chunk, null, 2
    catch error
      console.error "Stream handling error:", error
      throw error


  call: ({sessionId, messageStubId, text}) ->
    try
      threadId = await @upsertThreadId {sessionId}
      console.log "call", {sessionId, messageStubId, text, threadId}
      response = @client.runs.stream threadId, @graphName,
        input:
          messages: text
        streamMode: "messages"

      @processStream {sessionId, response, messageStubId}
    catch error
      console.error "LangGraphChatBot error:", error
      await @createLogMessage {sessionId, error: error}