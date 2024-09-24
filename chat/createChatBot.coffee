import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {HumanMessage, AIMessage, SystemMessage, ToolMessage} from "@langchain/core/messages"
import {concat} from "@langchain/core/utils/stream"
import {ChatAnthropic} from '@langchain/anthropic'
import {ChatOpenAI} from '@langchain/openai'
import _ from 'lodash'


###*
  @param {Object} options
  @param {Object} options.chatClient - the langchain for the chat client
  @param {Boolean} options.stream - if true, the bot will stream its response
  @param {String} options.model - the model name to use
  @param {String} options.getSystemPrompt - a function that returns the system message the bot will ALLWAYS recive as first message
  @param {Function} [options.getTools=({sessionId = null}) => []] - a function that returns an array of tools that can be called by the bot
  @param {String} [options.toolChoice] - the function call mode
  @param {Object} [options.options={}] - additional options for the llm call
  @param {Number} [options.contextTokenLimit=8191 - 2000] - the token limit for the context
  @param {Boolean} [options.allowRecursiveToolCalls=false] - if true, the bot may call tools on 2nd call
  @param {Mongo.Collection} options.messageCollection
  @param {Object} [options.botUserData] - the user data for the bot
  ###
export createChatBot = ({
  chatClient,
  getSystemPrompt,
  getTools = ({sessionId = null}) -> []
  toolChoice,
  options = {}
  contextTokenLimit = 8191 - 2000
  allowRecursiveToolCalls = false
  messageCollection,
  botUserData
}) ->

  modelVendor = switch chatClient.constructor.name
    when 'ChatAnthropic'
      'anthropic'
    when 'ChatOpenAI'
      'openai'
    when 'ChatMistralAI'
      'mistral'
    else
      throw new Meteor.Error 'createChatBot: chatClient must be a ChatAnthropic or ChatOpenAI or ChatMistralAI instance'

  return unless Meteor.isServer

  unless messageCollection?
    throw new Meteor.Error 'createChatBot: messageCollection is required'

  handleStream = ({response, messageStubId}) ->
    done = false
    content = ''
    oldContent = ''
    finishReason = null
    usage = {}

    updateContent = ->
      if oldContent isnt content
        oldContent = content
        messageCollection.updateAsync messageStubId,
          $set:
            text: content
            workInProgress: true
            # createdAt: new Date()
    
    interval = Meteor.setInterval updateContent, 700

    for await chunk from response
      gathered = if gathered? then concat(gathered, chunk) else chunk

      # for anthropic
      if modelVendor is 'anthropic'
        finishReason = chunk?.additional_kwargs?.stop_reason
        usage = chunk?.additional_kwargs?.usage
        if chunk.content?[0]?.text?
          content = content + chunk.content[0].text
      
      # for openai
      if modelVendor is 'openai'
        finishReason = chunk?.response_metadata?.finish_reason
        content = content + chunk.content
        usage = chunk.usage_metadata

      # for mistral, mistral does not have an explicit finish_reason, instead, the last chunk will contain a usage_metadata field.
      if modelVendor is 'mistral'
        content = content + chunk.content
        usage = chunk.usage_metadata
        if usage
          finishReason = 'end_turn'
        if chunk.tool_calls.length > 0
          finishReason = 'tool_use'
      
      if finishReason
        done = true
        if finishReason in ['tool_use', 'tool_calls']
          messageCollection.updateAsync messageStubId,
            $set:
              tools: gathered.tool_calls
        if modelVendor is 'anthropic'
          unless finishReason in ['tool_use', 'end_turn']
            throw new Meteor.Error "handleStream: finish_reason #{finishReason}"
        else if modelVendor is 'openai'
          unless finishReason in ['tool_use', 'stop', 'tool_calls']
            throw new Meteor.Error "handleStream: finish_reason #{finishReason}"
        else if modelVendor is 'mistral'
          unless finishReason in ['end_turn', 'tool_use']
            throw new Meteor.Error "handleStream: finish_reason #{finishReason}"

    new Promise (resolve) ->
      if done
        updateContent()
        Meteor.clearInterval interval
        resolve gathered

  ###*
    Build the context for the chatbot call
    @param {Object} options
    @param {String} options.sessionId
    @param {Array} [options.additionalMessages=[]]
    @param {Number} [options.initialLimit=15]
    @example
      chatBot.buildContext
        sessionId: '123'
        additionalMessages: [{content: 'Talk like a Pirate! Harrr!', role: 'system'}]
        initialLimit: 20
    ###
  buildContext =  ({sessionId, additionalMessages = [], initialLimit = 15}) ->
    debugger
    fetchedSystemPrompt = getSystemPrompt?()
    system = if typeof fetchedSystemPrompt is 'string'
      fetchedSystemPrompt
    else "Du bist ein freundlicher, hilfreicher Chatbot"
    query =
      sessionId: sessionId
      chatRole: $ne: 'log'
      # workInProgress: $ne: true

    total_tokens = 0
    history =
      _(await messageCollection.find query,
        sort: {createdAt: -1}
        limit: initialLimit
      .fetchAsync())
      .reverse()
      .map (message, i, messages) ->
        debugger
        switch
          when message.chatRole is 'system'
            new SystemMessage message.text
          when message.chatRole is 'user'
            new HumanMessage message.text
          when message.chatRole is 'function'
            toolResult = switch modelVendor
              when "anthropic"
                new HumanMessage
                  content: [
                      type: 'tool_result'
                      content: message.text
                      tool_use_id: message.tool_id #message.tool_use_id
                    ]
              when "openai", "mistral"
                new ToolMessage
                  content: message.text
                  tool_call_id: message.tool_id
              else
                throw new Error "Unsupported model vendor: #{modelVendor}"
            # we return an array here because we might need to add a dummy message before the tool result
            # we will flatten this out later
            [
              # check if the previous message was the tool call that triggered this function call
              unless messages[i - 1]?.tools?.map((tool) -> tool.id).includes message.tool_id
                # we generate a dummy assistant message with the tool call to make the context correct
                previousTools = messages.find( (m) -> m.tool_id is message.tool_id)?.tools
                new AIMessage
                  content: 'You were about to call a function when you where interupted by the user'
                  tool_calls: previousTools
              toolResult
            ]
          when message.chatRole is 'assistant'
            return null if i is 0 # skip welcome (anthropic dies if user isnt first in history)
            return null if i is messages.length - 1 # last message may not be assistant message
            new AIMessage
              content: message.text
              tool_calls: message.tools
          else
            throw new Meteor.Error 'buildContext: unknown chatRole: ' + message.chatRole
      .flatten()
      .compact()
      .filter (message) -> message.content?.length
      .value()
    system_msg = new SystemMessage system
    [system_msg, history...]


  ###*
    @description
    - create a new message stub
    - sets createdAt, chatRole to 'assistant'
    - and workInProgress to 'true
    @param {Object} options
    @param {String} options.sessionId
    @param {String} [options.text='']
    @returns {String} the id of the new message stub
    ###
  createMessageStub = ({sessionId, text = ''}) ->
    messageCollection.insertAsync
      userId: botUserData.id
      sessionId: sessionId
      text: text
      chatRole: 'assistant'
      createdAt: new Date()
      workInProgress: true
  
  
  ###*
    @description
    - sets createdAt to new Date()
    - sets text to the new text
    @param {Object} options
    @param {String} options.messageId
    @param {String} options.text
    @returns {String} the id of the Message
    ###
  updateMessageStub = ({messageId, text}) ->
    messageCollection.updateAsync messageId,
      $set:
        text: text
        # createdAt: new Date()
  ###*
    @description
    - sets createdAt to new Date()
    - and workInProgress to 'false
    @param {Object} options
    @param {String} options.messageId
    @param {String} options.text
    @param {Object} [options.usage]
    @returns {String} the id of the Message
    ###
  finalizeMessageStub = ({messageId, text, usage}) ->
    usage?.model ?= chatClient.model
    messageCollection.updateAsync messageId,
      $set:
        # createdAt: new Date()
        workInProgress: false
        text: text
        usage: usage


###*
 * Creates and inserts a log message into the message collection.
 * @param {Object} options - The options for creating the log message.
 * @param {string} options.sessionId - The ID of the session.
 * @param {string} [options.text] - The text content of the message.
 * @param {Object} [options.toolCall] - Information about a tool call, if applicable.
 * @param {Error} [options.error] - An error object, if an error occurred.
 * @param {Object} [options.usage] - Usage statistics for the message.
 * @returns {Promise<Object>} A promise that resolves with the inserted document.
###
  createLogMessage = ({sessionId, text = undefined, toolCall = undefined, error = undefined, usage = undefined}) ->
    messageCollection.insertAsync
      userId: botUserData.id
      sessionId: sessionId
      text: text
      toolCall: toolCall
      error: error
      chatRole: 'log'
      createdAt: new Date()
      workInProgress: false
      usage: usage

  ###*
    Call the chatbot handle the response and function calls
    @param {Object} options
    @param {String} options.sessionId
    @param {String} options.messageId - the id of the message stub
    @param {Array} options.messages
    @param {Boolean} [options.allowFunctionCall=true] - if false, the bot will not call any functions
    @example
      chatBot.call
        sessionId: '123'
        messages: [{content: 'Hallo', role: 'user'}]
    ###
  call = ({sessionId, messageId, messages, allowFunctionCall = true}) ->

    
    toolsWithRun = getTools({sessionId, messageId})
    tools = toolsWithRun.map (f) -> _.omit f, 'run'


    if modelVendor is 'openai' or modelVendor is 'mistral'
      modelWithTools = chatClient.bindTools(tools)
    else if modelVendor is 'anthropic'

      tools_anthropic = tools.map (t) ->
        t['input_schema'] = t["parameters"]
        delete t["parameters"]
        tool_json = JSON.stringify t
        t = JSON.parse(tool_json)
        t
      modelWithTools = chatClient.bindTools(tools_anthropic)

    # for anthropic, we also must pass the tool definitions when we pass tool results.
    model_used = if allowFunctionCall or modelVendor is 'anthropic' or modelVendor is 'mistral' then modelWithTools else chatClient


    model_used.stream messages
    .then (response) ->
      handleStream {response, messageStubId: messageId}
    .catch (error) ->
      throw error
    .then (response) ->

      prompt_tokens = response.usage_metadata.input_tokens
      completion_tokens = response.usage_metadata.output_tokens

      # openai or mistral
      if modelVendor is "openai" or modelVendor is "mistral"
        content = response.content
      else if modelVendor is "anthropic"
        content = response.content[0].text


      usage =
        model: model_used.model
        prompt: prompt_tokens
        completion: completion_tokens

      toolCalls = response?.tool_calls
      finalizeMessageStub {messageId, text: content, usage}
      
      if toolCalls? and toolCalls.length
        Promise.allSettled toolCalls.map (tc) ->
          return unless tc.args?
          
          # createLogMessage {sessionId, toolCall: tc, usage}
          tool_selected = (toolsWithRun.find (t) -> t.function.name is tc.name)
          result = await tool_selected?.run tc.args
          await messageCollection.insertAsync
            userId: botUserData.id
            sessionId: sessionId
            chatRole: 'function'
            createdAt: new Date()
            workInProgress: false
            text: result
            tool_id: tc.id
            args: tc.args
            function_name: tc.name
          
          messagesWithResult = await buildContext {sessionId}

          # create a new message for the answer of the chatbot to the function call result.
          newMessageId = await createMessageStub {sessionId, text: ''}
          call {sessionId, messageId: newMessageId, messages: messagesWithResult, allowFunctionCall: allowRecursiveToolCalls}
    .catch (error) ->
      createLogMessage {sessionId, error: error}
      throw error

  {call, createMessageStub, updateMessageStub, finalizeMessageStub, buildContext}