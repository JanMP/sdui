import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {tokenizer} from 'meteor/janmp:sdui'
import _ from 'lodash'

countTokens = (messages) ->
  messages
  .map (m) -> tokenizer.encode m.content ? ''
  .reduce ((a, b) -> a + b.length), 0

###*
  @param {Object} options
  @param {Object} options.chatClient - the js chat client
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
  stream = false,
  model, getSystemPrompt,
  getTools = ({sessionId = null}) -> []
  toolChoice,
  options = {}
  contextTokenLimit = 8191 - 2000
  allowRecursiveToolCalls = false
  messageCollection,
  botUserData
}) ->
  return unless Meteor.isServer

  handleStream = ({response, messageStubId}) ->
    done = false
    content = ''
    oldContent = ''
    finishReason = null
    objectFromDeltas = {}
    toolCalls = []

    addDelta = ({objectFromDeltas, delta}) ->
      for key of delta
        objectFromDeltas[key] = switch
          when key is 'tool_calls'
            for toolCallChunk in delta.tool_calls # special handling of tool_calls
              if toolCalls.length <= toolCallChunk.index
                toolCalls.push
                  id: ''
                  type: 'function'
                  function:
                    name: ''
                    arguments: ''
              toolCall = toolCalls[toolCallChunk.index]
              if toolCallChunk.id?
                toolCall.id += toolCallChunk.id
              if toolCallChunk.function?.name?
                toolCall.function.name += toolCallChunk.function.name
              if toolCallChunk.function?.arguments?
                toolCall.function.arguments += toolCallChunk.function.arguments
          when delta[key] is null then null
          when typeof delta[key] is 'string'
            (objectFromDeltas?[key] ? '') + delta[key]
          when typeof delta[key] is 'object'
            addDelta {objectFromDeltas: (objectFromDeltas?[key] ? {}), delta: delta[key]}
          else
            throw new Meteor.Error "handleStream: addDelta: unknown type #{typeof delta[key]}"
      objectFromDeltas

    updateContent = ->
      if oldContent isnt content
        oldContent = content
        messageCollection.update messageStubId,
          $set:
            text: content
            createdAt: new Date()
            workInProgress: true
    
    interval = Meteor.setInterval updateContent, 700

    for await chunk from response
      try
        delta = chunk?.choices?[0]?.delta
        finishReason = chunk?.choices?[0]?.finish_reason
        objectFromDeltas = addDelta {objectFromDeltas, delta}
        content = objectFromDeltas.content
        # console.log 'delta', JSON.stringify delta, null, 2
        if finishReason
          done = true
          unless finishReason in ['stop','tool_calls']
            throw new Meteor.Error "handleStream: finish_reason #{finishReason}"
      catch error
        done = true
        throw new Meteor.Error "handleStream: #{error.message}"

    new Promise (resolve) ->
      if done
        updateContent()
        Meteor.clearInterval interval
        resolve
          message:
            content: content
            role: 'assistant'
            tool_calls: toolCalls
          usage:
            model: model
            prompt: 0
            completion: 0

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
    history =
      messageCollection.find query,
        sort: {createdAt: -1}
        limit: initialLimit
      .fetch()
      .filter (message) -> message.text?
      .reverse()
      .map (message) ->
        # console.log 'message', message
        role: message.chatRole
        content: message.text
    build = (limit) ->
      if limit < 0
        throw new Meteor.Error 'buildHistory: limit must be >= 0'
      croppedHistory = history[0..limit]
      messages = [{content: system, role: 'system'}, croppedHistory..., additionalMessages...]
      try
        if tokenizer.isWithinTokenLimit messages, contextTokenLimit
          messages
        else
          console.log 'buildHistory: tokenLimit reached, trying again with limit ', limit - 1
          build limit - 1
      catch error
        console.error "The tokenizer is broken: #{error.message}"
        messages

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
    messageCollection.updateAsync messageId,
      $set:
        createdAt: new Date()
        workInProgress: false
        text: text
        usage: usage

  createSystemMessage = ({sessionId, text, usage = undefined}) ->
    messageCollection.insertAsync
      userId: botUserData.id
      sessionId: sessionId
      text: text
      chatRole: 'system'
      createdAt: new Date()
      workInProgress: false
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
    Call the chatbot handle the response and functioncalls
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
    callFkt = if stream then chatClient.chatStream else chatClient.chat
    toolsWithRun = getTools({sessionId, messageId})
    tools = toolsWithRun.map (f) -> _.omit f, 'run'
    params = {
      model, messages, options...,
      tools: if allowFunctionCall then tools,
      tool_choice: if allowFunctionCall then toolChoice,
      # responseType: if options?.stream then 'stream'
    }
    callFkt params
    .then (response) ->
      if stream
        handleStream {response, messageStubId: messageId}
      else
        message: response.choices[0].message
        usage: response.usage
    .then (response) ->
      message = response.message
      prompt_tokens =
        if options?.stream
          countTokens messages
        else
          response?.usage.prompt_tokens ? 0
      completion_tokens =
        if options?.stream
          countTokens [message]
        else
          response?.usage.completion_tokens ? 0
      usage =
        model: model
        prompt: prompt_tokens
        completion: completion_tokens
      unless (toolCalls = message?.tool_calls)? and toolCalls.length
        finalizeMessageStub {messageId, text: message?.content, usage}
      else
        Promise.allSettled toolCalls.map (tc) ->
          return unless tc.function?.arguments?
          tc.function.arguments =
            if typeof tc.function.arguments is 'string'
              JSON.parse tc.function.arguments
            else tc.function.arguments
          createLogMessage {sessionId, toolCall: tc, usage}
          (toolsWithRun.find (t) -> t.function.name is tc.function.name)?.run tc.function.arguments
        .then (result) ->
          return unless result?
          createSystemMessage {sessionId, text: JSON.stringify result}
          messagesWithResult = buildContext {sessionId}
          call {sessionId, messageId: messageId, messages: messagesWithResult, allowFunctionCall: allowRecursiveToolCalls}
    .catch (error) ->
      createLogMessage {sessionId, error: error}
      throw error

  {call, createMessageStub, updateMessageStub, finalizeMessageStub, buildContext}