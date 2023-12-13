import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {setupOpenAIApi} from '../ai/setupOpenAIApi.coffee'
import {tokenizer} from 'meteor/janmp:sdui'
import omit from 'lodash/omit'
import merge from 'lodash/merge'


countTokens = (messages) ->
  messages
  .map (m) -> tokenizer.encode m.content ? ''
  .reduce ((a, b) -> a + b.length), 0

###*
  @param {Object} options
  @param {Mongo.Collection} options.messageCollection
  @param {String} options.model - the OpenAI model to use
  @param {String} options.getSystemPrompt - a function that returns the system message the bot will ALLWAYS recive as first message
  @param {Object} [options.options={}] - the options for the OpenAI API
  @param {Object} [options.botUserData] - the user data for the bot
  @param {Function} [options.getFunctions] - a function that returns an array of functions that can be called by the bot
  @param {String} [options.functionCall] - the function call mode, can be 'auto', 'none' or 'manual'
  @param {Number} [options.contextTokenLimit=8191 - 2000] - the token limit for the context
  @param {String} [options.version] - the version of the chatbot, for logging
  ###
export createChatBot = ({
  model, getSystemPrompt, options = {},
  messageCollection,
  botUserData
  getFunctions = ({sessionId = null}) -> []
  functionCall = 'none'
  contextTokenLimit = 8191 - 2000
}) ->
  return unless Meteor.isServer
  console.log 'createChatBot', {model, getSystemPrompt, options, messageCollection, botUserData, getFunctions, functionCall, contextTokenLimit}

  model ?= 'gpt-3.5-turbo'
  openAI = setupOpenAIApi()

  handleStream = ({response, messageStubId}) ->
    done = false
    content = ''
    oldContent = ''
    finishReason = null
    objectFromDeltas = {}

    addDelta = ({objectFromDeltas, delta}) ->
      for key of delta
        objectFromDeltas[key] =
          if delta[key] is null then null
          else if typeof delta[key] is 'string'
            (objectFromDeltas?[key] ? '') + delta[key]
          else if typeof delta[key] is 'object'
            addDelta {objectFromDeltas: (objectFromDeltas?[key] ? {}), delta: delta[key]}
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
        if finishReason
          done = true
          unless finishReason in ['stop','function_call']
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
            function_call: {name: objectFromDeltas.function_call?.name, arguments: try JSON.parse objectFromDeltas.function_call?.arguments}
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
          # console.log 'buildHistory: tokenLimit not reached'
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

  createLogMessage = ({sessionId, text = undefined, functionCall = undefined, error = undefined, usage = undefined}) ->
    messageCollection.insertAsync
      userId: botUserData.id
      sessionId: sessionId
      text: text
      functionCall: functionCall
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
    @example
      chatBot.call
        sessionId: '123'
        messages: [{content: 'Hallo', role: 'user'}]
    ###
  call = ({sessionId, messageId, messages}) ->
    functions = getFunctions({sessionId, messageId})
    functionParams = functions.map (f) -> omit f, 'run'
    openAI.chat.completions.create {
      model, messages, options...,
      functions: functionParams, function_call: functionCall},
      {responseType: if options?.stream then 'stream'}
    .then (response) ->
      if options.stream
        handleStream {response, messageStubId: messageId}
      else
        # console.log 'response.data', response?.data
        message: response.choices[0].message
        usage: response.usage
    .then (response) ->
      # console.log 'response', response
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
      unless (fc = message?.function_call)?.name
        finalizeMessageStub {messageId, text: message?.content, usage}
      else
        fc.arguments =
          if typeof fc.arguments is 'string'
            JSON.parse fc.arguments
          else fc.arguments
        createLogMessage {sessionId, functionCall: fc, usage}
        (functions.find (f) -> f.name is fc.name)?.run fc.arguments
        .then (result) ->
          createSystemMessage {sessionId, text: result}
          messagesWithResult = buildContext {sessionId}
          call {sessionId, messageId: messageId, messages: messagesWithResult}
    .catch (error) ->
      createLogMessage {sessionId, error: error}
      throw error

  {call, createMessageStub, updateMessageStub, finalizeMessageStub, buildContext}