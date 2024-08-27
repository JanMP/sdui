import {Meteor} from 'meteor/meteor'
import {ChatAnthropic} from '@langchain/anthropic'
import {ChatOpenAI} from '@langchain/openai'

export setupChatModel = ({vendor = 'openai', model = 'gpt-4o-mini', temperature = 0, streaming = false, apiKey = 'fnord'}) ->

  constructor =
    switch vendor
      when 'openai' then ChatOpenAI
      when 'anthropic' then ChatAnthropic
      else throw new Meteor.Error "Unsupported vendor: #{vendor}"

  new constructor {model, temperature, streaming, apiKey}