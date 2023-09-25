import {Meteor} from 'meteor/meteor'
import {setupOpenAIApi} from '../ai/setupOpenAIApi.coffee'
import {tokenizer} from 'meteor/janmp:sdui'
import omit from 'lodash/omit'
import merge from 'lodash/merge'

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
  openAi = setupOpenAIApi()
  replyMessageId = null

  handleStream = (reply) ->
    done = false
    text = ''
    deltas = []
    function_call =
      name: null
      arguments: ''
    
    reply?.data?.on 'data', Meteor.bindEnvironment (chunk) ->
      chunk.toString()
      .split '\n'
      .filter (line) -> line.trim() isnt ''
      .forEach (line) ->
        line = line.replace?(/^data: /, '') ? line
        if line is '[DONE]' or typeof line isnt 'string'
          done = true
          return
        try
          response = JSON.parse line
          dContent = response?.choices?[0]?.delta?.content ? ''
          text += dContent
          deltas.push dContent
          # unless response?.choices?
          #   console.log 'response:', response
          if (name = response?.choices?[0]?.delta?.function_call?.name)?
            function_call.name = name
          if (args = response?.choices?[0]?.delta?.function_call?.arguments)?
            function_call.arguments += args

    new Promise (resolve) ->
      interval = Meteor.setInterval ->
        # console.log 'interval'
        chatCollection.update replyMessageId,
          $set:
            text: text
            createdAt: new Date()
        if done
          Meteor.clearInterval interval
          resolve
            message:
              content: text
              role: 'assistant'
              function_call: {name: function_call.name, arguments: try JSON.parse function_call.arguments}
            usage:
              model: model
              prompt: 0
              completion: 0
      , 200

  ###*
    Build the context for the chatbot call
    @param {Object} options
    @param {String} options.sessionId
    @param {Array} [options.additionalMessages=[]]
    @param {Number} [options.initialLimit=20]
    @example
      chatBot.buildContext
        sessionId: '123'
        additionalMessages: [{content: 'Talk like a Pirate!' Harrr!', role: 'system'}]
        initialLimit: 20
    ###
  buildContext: ({sessionId, additionalMessages = []}, initialLimit = 20) ->
    build = (limit) ->
      if limit < 0
        throw new Meteor.Error 'buildHistory: limit must be >= 0'
      history =
        chatCollection.find {sessionId, workInProgress: {$ne: true}},
          sort: {createdAt: -1}
          limit: limit
        .fetch()
        .reverse()
        .map (message) ->
          role: message.chatRole
          content:
            message.text
            .replace /\[\/\/\]: # \(hide from llm start\)[\s\S]*?\[\/\/\]: # \(hide from llm end\)/g, ''
      messages = [{content: system, role: 'system'}, history..., additionalMessages...]
      if tokenizer.isWithinTokenLimit messages, contextTokenLimit
        # console.log 'buildHistory: tokenLimit not reached'
        messages
      else
        console.log 'buildHistory: tokenLimit reached, trying again with limit ', limit - 1
        build limit - 1

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
  createMessageStub: ({sessionId, text = ''}) ->
    replyMessageId = chatCollection.insert
      userId: botUserData.id
      sessionId: sessionId
      text: text
      chatRole: 'assistant'
      createdAt: new Date()
      workInProgress: true
    replyMessageId


  updateMessageStub: ({messageId, text}) ->
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
    @returns {String} the id of the 
    ###
  finalizeMessageStub: ({messageId}) ->
    chatCollection.update messageId,
      $set:
        createdAt: new Date()
        workInProgress: false

  call:
    ###*
      Call the chatbot handle the response and functioncalls
      @param {Object} options
      @param {String} options.sessionId
      @param {Array} options.messages
      @param {Object} options.logData
      @example
        chatBot.call
          sessionId: '123'
          messages: [{content: 'Hallo', role: 'user'}]
          logData:
            userId: '123'
            messageId: '456'
            bot: 'chatBot'
            version: '4.0.0'
      ###
    call = ({sessionId, messages, logData}) ->

      functions = getFunctions({sessionId})
      functionParams = functions.map (f) -> omit f, 'run'
      openAi.createChatCompletion {model, messages, options..., functions: functionParams, function_call: functionCall}, {responseType: if options?.stream then 'stream'}
      .then (response) ->
        if options.stream
          handleStream response
        else
          response?.data?.choices?[0]?.message
      .then (response) ->
        # console.log response
        if logCollection and Meteor.isServer
          logCollection.insert {
            model
            messages
            response...
            createdAt: new Date()
            logData...
          }
        if (fc = response.message.function_call)?.name
          console.log 'function_call', fc
          (functions.find (f) -> f.name is fc.name)?.run fc.arguments
          .then (result) ->
            console.log result
            messagesWithResult = messages.concat {content: result, role: 'system'}
            call {messages: messagesWithResult, logData}
        response
      .catch console.error


  test: -> console.log 'test', {works: true}