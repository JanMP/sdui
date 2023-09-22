import {Meteor} from 'meteor/meteor'
import {setupOpenAIApi} from '../ai/setupOpenAIApi.coffee'
import {tokenizer} from 'meteor/janmp:sdui'
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
  logCollection
  chatCollection
  botUserData
  contextTokenLimit = 4096 - 1000
}) ->
  return unless Meteor.isServer

  model ?= 'gpt-3.5-turbo'
  system ?= "Du bist ein freundlicher, hilfreicher Chatbot"
  openAi = setupOpenAIApi()
  replyMessageId = null

  handleStream = (reply) ->
    text = ''
    done = false
    
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
          delta = response?.choices?[0]?.delta?.content ? ''
          text += delta

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
      messages = [content: system, role: 'system', history..., additionalMessages...]
      if tokenizer.isWithinTokenLimit messages, contextTokenLimit
        # console.log 'buildHistory: tokenLimit not reached'
        messages
      else
        # console.log 'buildHistory: tokenLimit reached, trying again with limit ', limit - 1
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
      createdAt: new Date()      workInProgress: true
    replyMessageId


  updateMessageStub: ({messageId, text}) ->
    chatCollection.update messageId,
      $set:
        text: text        createdAt: new Date()


  finalizeMessageStub: ({messageId}) ->
    chatCollection.update messageId,
      $set:
        createdAt: new Date()
        workInProgress: false


  call: ({messages, logData}) ->
    openAi.createChatCompletion {model, messages, options...}, {responseType: if options?.stream then 'stream'}
    .then (reply) ->
      if options.stream
        handleStream reply
      else
        if logCollection and Meteor.isServer
          logCollection.insert {
            model
            messages,
            message: reply?.data?.choices?[0].message
            usage: reply?.data?.usage
            createdAt: new Date()
            logData...
          }
        #return
        message: reply?.data?.choices?[0].message
        usage:
          model: model
          prompt: reply?.data?.usage?.prompt_tokens
          completion: reply?.data?.usage?.completion_tokens
    .catch console.error


  test: -> console.log 'test', {works: true}