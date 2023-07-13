import {Meteor} from 'meteor/meteor'
import {setupOpenAIApi} from 'meteor/janmp:chatterbrain'

export createChatBot = ({
  model, system
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
    openAi.createChatCompletion
      model: model
      messages: messages
    .then (result) -> result?.data?.choices[0]
    .catch console.error
  test: -> console.log 'test', {works: true}