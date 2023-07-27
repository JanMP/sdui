import {Meteor} from 'meteor/meteor'
import {setupOpenAIApi} from 'meteor/janmp:chatterbrain'
 
export createChatBot = ({
  model, system, options = {},
  logCollection
}) ->
  return unless Meteor.isServer
  model ?= 'gpt-3.5-turbo'
  system ?= "Du bist ein freundlicher, hilfreicher Chatbot"
  openAi = setupOpenAIApi()

  call: ({history, logData}) ->
    messages = [
      content: system, role: 'system'
    , history...
    ]
    openAi.createChatCompletion {model, messages, options...}, {responseType: if options?.stream then 'stream'}
    .then (result) ->
      if options.stream
        result
      else
        if logCollection and Meteor.isServer
          logCollection.insert {
            model
            messages,
            message: result?.data?.choices?[0].message
            usage: result?.data?.usage
            createdAt: new Date()
            logData...
          }
        #return
        message: result?.data?.choices?[0].message
        usage:
          model: model
          prompt: result?.data?.usage?.prompt_tokens
          completion: result?.data?.usage?.completion_tokens
    .catch console.error
  test: -> console.log 'test', {works: true}