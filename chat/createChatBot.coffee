import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import _ from 'lodash'
import { HumanMessage, AIMessage, SystemMessage, ToolMessage } from "@langchain/core/messages";
import { concat } from "@langchain/core/utils/stream";
import { ChatAnthropic } from '@langchain/anthropic'
import { ChatOpenAI } from '@langchain/openai'

countTokens = (messages) ->
  messages
  .map (m) -> tokenizer.encode m.content ? ''
  .reduce ((a, b) -> a + b.length), 0



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
      throw new Meteor.Error 'createChatBot: chatClient must be a ChatAnthropic or ChatOpenAI instance'

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
            createdAt: new Date()
            workInProgress: true
    
    interval = Meteor.setInterval updateContent, 700

    for await chunk from response
      gathered = if gathered? then concat(gathered, chunk) else chunk

      # console.log chunk

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
    fetchedSystemPrompt = getSystemPrompt?()
    system = if typeof fetchedSystemPrompt is 'string' then fetchedSystemPrompt else "Du bist ein freundlicher, hilfreicher Chatbot"
    query =
      sessionId: sessionId
      workInProgress: $ne: true
      chatRole: $ne: 'log'

    total_tokens = 0
    history =
      (await messageCollection.find query,
        sort: {createdAt: -1}
        limit: initialLimit
      .fetchAsync())
      .reverse()
      .map (message) ->
        msg = switch
          when message.chatRole is 'system'
            new SystemMessage message.text
          when message.chatRole is 'user'
            new HumanMessage message.text
          when message.chatRole is 'function'
            if modelVendor is "anthropic"
              new HumanMessage
                content: [
                  {
                    type: 'tool_result',
                    content: message.text
                    tool_use_id: message.tool_id #message.tool_use_id
                  }
                ]
            else if modelVendor is "openai"
              new ToolMessage {
                content: message.text
                tool_call_id: message.tool_id
              }
            else if modelVendor is "mistral"
              new ToolMessage {
                content: message.text
                tool_call_id: message.tool_id
              }
          when message.chatRole is 'assistant'
            new AIMessage
              content: message.text
              tool_calls: message.tools
          else
            throw new Meteor.Error 'buildContext: unknown chatRole'
    
    build = (limit) -> # TODO we don't have the tokenizer anymore, this whole aproach needs to be reworked
      if limit < 0
        throw new Meteor.Error 'buildHistory: limit must be >= 0'
      croppedHistory = history[1..limit]
      system_msg = new SystemMessage system
      [system_msg, additionalMessages..., croppedHistory...]

    build initialLimit


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
    ###
  updateMessageStub = ({messageId, text}) ->
    messageCollection.updateAsync messageId,
      $set:
        text: text
        createdAt: new Date()
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
        createdAt: new Date()
        workInProgress: false
        text: text
        usage: usage


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