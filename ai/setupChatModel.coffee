import {Meteor} from 'meteor/meteor'
import {ChatAnthropic} from '@langchain/anthropic'
import {ChatOpenAI} from '@langchain/openai'
import {ChatMistralAI} from '@langchain/mistralai'

###*
  Creates and returns a chat model instance based on the provided settings.
  @param {Object} settings - The configuration settings for the chat model.
  @param {('openai'|'anthropic'|'mistral')} settings.vendor - The vendor name.
  @returns {ChatOpenAI|ChatAnthropic|ChatMistralAI} The instantiated chat model.
  ###
export setupChatModel = (settings) ->
  {vendor,options...} = settings
  constructor =
    switch vendor
      when 'openai' then ChatOpenAI
      when 'anthropic' then ChatAnthropic
      when 'mistral' then ChatMistralAI
      else throw new Meteor.Error "Unsupported vendor: #{vendor}"

  new constructor options