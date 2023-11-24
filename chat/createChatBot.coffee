import {Meteor} from 'meteor/meteor'
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
  @param {String} options.model - the OpenAI model to use
  @param {String} options.system - the system message the bot will ALLWAYS recive as first message
  @param {Object} [options.options={}] - the options for the OpenAI API
  @param {Object} [options.chatCollection] - the createShatAPI collection
  @param {Object} [options.botUserData] - the user data for the bot
  @param {Function} [options.getFunctions] - a function that returns an array of functions that can be called by the bot
  @param {String} [options.functionCall] - the function call mode, can be 'auto', 'none' or 'manual'
  @param {Object} [options.logCollection] - the collection to log the chatbot calls
  @param {Number} [options.contextTokenLimit=8191 - 2000] - the token limit for the context
  ###
export createChatBot = ({
  model, system, options = {},
  chatCollection
  botUserData
  getFunctions = ({sessionId = null}) -> []
  functionCall = 'none'
  logCollection
  contextTokenLimit = 8191 - 2000
}) ->
  return unless Meteor.isServer

  model ?= 'gpt-3.5-turbo'
  system ?= "Du bist ein freundlicher, hilfreicher Chatbot"
  openAI = setupOpenAIApi()
  replyMessageId = null

  handleStream = (reply) ->
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
        chatCollection.update replyMessageId,
          $set:
            text: content
            createdAt: new Date()
            workInProgress: true
    
    interval = Meteor.setInterval updateContent, 700

    for await chunk from reply
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
    @param {Number} [options.initialLimit=20]
    @param {Number} [options.timeLimit] - the time limit for the messages
    @example
      chatBot.buildContext
        sessionId: '123'
        additionalMessages: [{content: 'Talk like a Pirate! Harrr!', role: 'system'}]
        initialLimit: 20
    ###
  buildContext =  ({sessionId, additionalMessages = [], initialLimit = 15, timeLimit}) ->
    query = if timeLimit?
      sessionId: sessionId
      workInProgress: {$ne: true}
      createdAt:
        $gte: new Date(new Date() - timeLimit)
    else
      {sessionId, workInProgress: {$ne: true}}
    build = (limit) ->
      if limit < 0
        throw new Meteor.Error 'buildHistory: limit must be >= 0'
      history =
        chatCollection.find query,
          sort: {createdAt: -1}
          limit: limit
        .fetch()
        .filter (message) -> message.text?
        .reverse()
        .map (message) ->
          # console.log 'message', message
          role: message.chatRole
          content: message.text
      messages = [{content: system, role: 'system'}, history..., additionalMessages...]
      try
        if tokenizer.isWithinTokenLimit messages, contextTokenLimit
          # console.log 'buildHistory: tokenLimit not reached'
          messages
        else
          console.log 'buildHistory: tokenLimit reached, trying again with limit ', limit - 1
          build limit - 1
      catch error
        console.error "The fucking tokenizer is broken: #{error.message}"
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
    replyMessageId = chatCollection.insert
      userId: botUserData.id
      sessionId: sessionId
      text: text
      chatRole: 'assistant'
      createdAt: new Date()
      workInProgress: true
    replyMessageId

  ###*
    @description
    - sets createdAt to new Date()
    - sets text to the new text
    ###
  updateMessageStub = ({messageId, text}) ->
    chatCollection.update messageId,
      $set:
        text: text
        createdAt: new Date()

  ###*
    @description
    - sets createdAt to new Date()
    - and workInProgress to 'false
    @param {Object} options
    @param {String} options.messageId
    @returns {String} the id of the Message
    ###
  finalizeMessageStub = ({messageId}) ->
    chatCollection.update messageId,
      $set:
        createdAt: new Date()
        workInProgress: false

  createSystemMessage = ({sessionId, text}) ->
    chatCollection.insert
      userId: botUserData.id
      sessionId: sessionId
      text: text
      chatRole: 'system'
      createdAt: new Date()
      workInProgress: false


  ###*
    Call the chatbot handle the response and functioncalls
    @param {Object} options
    @param {String} options.sessionId
    @param {Object} options.message
    @param {String} [options.messageId] - the id of the message stub
    @param {Array} options.messages
    @param {Object} options.logData
    @example
      chatBot.call
        sessionId: '123'
        messages: [{content: 'Hallo', role: 'user'}]
        logData:
          bot: 'chatBot'
          version: '1.0.0'
    ###
  call = ({sessionId, message, messageId, messages, logData}) ->

    if logCollection and Meteor.isServer and message?
      logCollection.insert {
        model
        messageId
        sessionId
        message
        createdAt: new Date()
        usage:
          model: model
          prompt_tokens: 0
          completion_tokens: 0
        logData...
      }

    functions = getFunctions({sessionId, messageId})
    functionParams = functions.map (f) -> omit f, 'run'
    openAI.chat.completions.create {
      model, messages, options...,
      functions: functionParams, function_call: functionCall},
      {responseType: if options?.stream then 'stream'}
    .then (response) ->
      if options.stream
        handleStream response
      else
        # console.log 'response.data', response?.data
        message: response.choices[0].message
        usage: response.usage
    .then (response) ->
      # console.log 'response', response
      message = response.message
      if logCollection and Meteor.isServer
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
        logCollection.insert {
          model
          messageId
          sessionId
          message
          createdAt: new Date()
          usage:
            model: model
            prompt_tokens: prompt_tokens
            completion_tokens: completion_tokens
          logData...
        }
      updateMessageStub {messageId, text: message?.content}
      finalizeMessageStub {messageId}
      if (fc = message?.function_call)?.name
        console.log 'function_call', fc
        (functions.find (f) -> f.name is fc.name)?.run fc.arguments
        .then (result) ->
          systemMessage =
            content: result
            role: 'system'
          # if logCollection and Meteor.isServer
          #   logCollection.insert {
          #     model
          #     messageId
          #     sessionId
          #     message: systemMessage
          #     createdAt: new Date()
          #     usage:
          #       model: model
          #       prompt_tokens: 0
          #       completion_tokens: 0
          #     logData...
          #   }
          systemMessageId = createSystemMessage {sessionId, text: result}
          messagesWithResult = buildContext {sessionId}
          call {sessionId, message: systemMessage, messageId: messageId, messages: messagesWithResult, logData}
        .catch (error) ->
          logCollection.insert {
            model
            messageId
            sessionId
            message:
              content: error.message
              role: 'system'
            createdAt: new Date()
            usage:
              model: model
              prompt_tokens: 0
              completion_tokens: 0
            logData...
          }
          throw new Meteor.Error error.message

  {call, createMessageStub, updateMessageStub, finalizeMessageStub, buildContext}