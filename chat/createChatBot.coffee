import {Meteor} from 'meteor/meteor'
import {setupOpenAIApi} from 'meteor/janmp:chatterbrain'

export createChatBot = ({
  model, system, options = {}
}) ->
  return unless Meteor.isServer
  model ?= 'gpt-3.5-turbo'
  system ?= "Du bist ein freundlicher, hilfreicher Chatbot"
  openAi = setupOpenAIApi()

  call: ({history}) ->
    messages = [
      content: system, role: 'system'
    , history...
    ]
    openAi.createChatCompletion {model, messages, options...}, {responseType: if options?.stream then 'stream'}
    .then (result) ->
      if options.stream
        result
      else
        result?.data?.choices?[0]
    .catch console.error
  test: -> console.log 'test', {works: true}