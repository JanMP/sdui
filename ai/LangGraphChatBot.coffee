# LangGraphChatBot.coffee (to be added to your sdui package)
import {Meteor} from 'meteor/meteor'
import _ from 'lodash'
import LangGraphSDK from '@langchain/langgraph-sdk'
import {defaultSdToolRegistry} from '../api/SdToolRegistry.coffee'

###*
  LangGraphChatBot class for handling chat interactions with LangGraph

  This class provides a complete interface for managing chat sessions, messages,
  and interactions with LangGraph. It handles streaming responses, message management,
  metadata tracking, and error handling.

  @example
  chatBot = new LangGraphChatBot({
    settings: {apiKey: 'your-api-key', endpoint: 'https://api.langgraph.com'},
    graphName: 'my-graph',
    messageCollection: Messages,
    sessionListCollection: Sessions,
    metaDataCollection: MetaData,
    botUserData: {id: 'bot-user-id'}
  })
###
export class LangGraphChatBot

  ###*
    Constructor for LangGraphChatBot

    @param {Object} options - Configuration object
    @param {Object} options.settings - LangGraph SDK settings and API configuration
    @param {string} options.graphName - Name of the LangGraph graph to use
    @param {Object} options.messageCollection - Meteor collection for storing messages
    @param {Object} options.sessionListCollection - Meteor collection for storing sessions
    @param {Object} options.metaDataCollection - Meteor collection for storing metadata
    @param {Object} options.botUserData - Bot user data object with id property
    @throws {Meteor.Error} When required parameters are missing
  ###
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

  ###*
    Get call parameters for LangGraph API including thread ID, model, and tools

    This method retrieves or creates a thread ID for the session and prepares
    the necessary parameters for making API calls to LangGraph.

    @param {Object} options - Configuration object
    @param {string} options.sessionId - The session ID to get parameters for
    @param {string} options.agentRole - The agent role to determine available tools
    @returns {Promise<Object>} Object containing threadId, model, and tools
    @throws {Meteor.Error} When required parameters are missing or session not found
  ###
  getCallParams: ({sessionId, agentRole}) ->
    unless agentRole?
      throw new Meteor.Error 'LangGraphChatBot: agentRole is required'
    unless sessionId?
      throw new Meteor.Error 'LangGraphChatBot: sessionId is required'
    unless (session = await @sessionCollection.findOneAsync sessionId)?
      throw new Meteor.Error 'LangGraphChatBot: session not found'
    savedThreadId = session.threadId
    threadId = savedThreadId ? (await @client.threads.create())?.thread_id
    if not savedThreadId?
      @sessionCollection.updateAsync sessionId,
        $set:
          threadId: threadId

    # Get tools for the agent role
    tools = defaultSdToolRegistry.getToolDefinitionsByRole agentRole
    console.log {agentRole, tools}

    {threadId, model: session.model ? 'openai/gpt-4.1', tools}

  ###*
    Create a message stub for streaming responses

    Creates a placeholder message that will be updated as the streaming response
    is received. Can be positioned after a specific message with a delay.

    @param {Object} options - Configuration object
    @param {string} options.sessionId - The session ID to create the message stub for
    @param {string} [options.text=''] - Initial text content for the message stub
    @param {string} [options.followMessageId] - ID of message to follow (for ordering)
    @param {number} [options.followDelay=1] - Delay in milliseconds after follow message
    @returns {Promise<string>} The ID of the created message stub
  ###
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

  ###*
    Update metadata item with additional data

    Updates an existing metadata item with new data and sets the updated timestamp.

    @param {Object} options - Configuration object
    @param {string} options.sessionId - The session ID of the metadata item
    @param {string} options.itemId - The item ID of the metadata item
    @param {Object} options.data - The data to update the metadata item with
    @returns {Promise<void>}
  ###
  updateMetaDataItem: ({sessionId, itemId, data}) ->
    @metaDataCollection.updateAsync {sessionId, itemId},
      $set:
        data: data
        updatedAt: new Date()

  ###*
    Update message stub with new text content

    Updates a message stub with new text content and optional tools data
    while keeping the workInProgress flag as true.

    @param {Object} options - Configuration object
    @param {string} options.messageStubId - The ID of the message stub to update
    @param {string} options.text - The new text content for the message stub
    @param {Object} [options.tools] - Optional tools data to include
    @returns {Promise<void>}
  ###
  updateMessageStub: ({messageStubId, text, tools = undefined}) ->
    @messageCollection.updateAsync messageStubId,
      $set:
        text: text
        tools: tools

  ###*
    Finalize message stub and mark as complete

    Finalizes a message stub by updating its content and marking it as no longer
    in progress. This indicates the message is complete and ready for display.

    @param {Object} options - Configuration object
    @param {string} options.messageStubId - The ID of the message stub to finalize
    @param {string} options.text - The final text content for the message
    @param {Object} options.tools - Tools data to include with the message
    @returns {Promise<void>}
  ###
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

  ###*
    Process streaming response from LangGraph

    Handles the streaming response from LangGraph API, processing different event types
    and updating message stubs and metadata as the response is received.

    @param {Object} options - Configuration object
    @param {string} options.sessionId - The session ID for the stream
    @param {AsyncIterable} options.response - The streaming response from LangGraph
    @param {string} options.messageStubId - The ID of the message stub to update
    @returns {Promise<void>}
    @throws {Error} When stream processing fails
  ###
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
            if Meteor.isDevelopment
              console.log "LangGraph Stream: unhandled event type:", chunk.event
            # console.log "#{"#".repeat 20} unknown chunk #{"#".repeat 20}"
            # console.log JSON.stringify chunk, null, 2
    catch error
      console.error "Stream handling error:", error
      throw error

  ###*
    Make a call to LangGraph with streaming response

    Initiates a call to LangGraph with the provided text and agent role,
    handling the streaming response and updating the message stub in real-time.

    @param {Object} options - Configuration object
    @param {string} options.sessionId - The session ID for the call
    @param {string} options.messageStubId - The ID of the message stub to update
    @param {string} options.text - The text message to send to LangGraph
    @param {string} options.agentRole - The agent role to use for the call
    @returns {Promise<void>}
    @throws {Meteor.Error} When required parameters are missing
    @throws {Error} When the LangGraph API call fails
  ###
  call: ({sessionId, messageStubId, text, agentRole}) ->
    unless sessionId?
      throw new Meteor.Error 'LangGraphChatBot: sessionId is required'
    unless messageStubId?
      throw new Meteor.Error 'LangGraphChatBot: messageStubId is required'
    unless text? and text.length
      throw new Meteor.Error 'LangGraphChatBot: text is required'
    unless agentRole?
      throw new Meteor.Error 'LangGraphChatBot: agentRole is required'
    try
      {threadId, model, tools} = await @getCallParams {sessionId, agentRole}
      # console.log "call", {sessionId, messageStubId, text, threadId}
      response = @client.runs.stream threadId, @graphName,
        input:
          messages: text
        config:
          configurable:
            model: model
            tools: tools
            meteor_session_id: sessionId
        streamMode: "messages"

      @processStream {sessionId, response, messageStubId}
    catch error
      console.error "LangGraphChatBot error:", error
      await @createLogMessage {sessionId, error: error}