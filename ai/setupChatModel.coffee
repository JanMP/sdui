import {Meteor} from 'meteor/meteor'
import {ChatAnthropic} from '@langchain/anthropic'
import {ChatOpenAI} from '@langchain/openai'

export setupChatModel = (settings) ->
  # console.log 'Setting up chat model with settings:', JSON.stringify settings
  {vendor,options...} = settings
  constructor =
    switch vendor
      when 'openai' then ChatOpenAI
      when 'anthropic' then ChatAnthropic
      else throw new Meteor.Error "Unsupported vendor: #{vendor}"

  new constructor options