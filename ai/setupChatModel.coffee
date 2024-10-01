import {Meteor} from 'meteor/meteor'
import {ChatAnthropic} from '@langchain/anthropic'
import {ChatOpenAI} from '@langchain/openai'
import {ChatMistralAI} from '@langchain/mistralai'

export setupChatModel = (settings) ->
  {vendor,options...} = settings
  constructor =
    switch vendor
      when 'openai' then ChatOpenAI
      when 'anthropic' then ChatAnthropic
      when 'mistral' then ChatMistralAI
      else throw new Meteor.Error "Unsupported vendor: #{vendor}"

  new constructor options