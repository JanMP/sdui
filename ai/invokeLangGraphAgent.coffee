import {Meteor} from 'meteor/meteor'
import LangGraphSDK from '@langchain/langgraph-sdk'


###*
  Simple Wrapper do hide away some of the boilerplate code for invoking LangGraph agents.
  @param {object} params
  @param {object} params.settings - The settings object for the LangGraph SDK.
  @param {string} params.agent - The agent to be invoked.
  @param {object} params.input - The input to be passed to the agent.
  @param {object} [params.config] - Optional configuration object (e.g., {model: 'openai/gpt-5'}).
  ###
export invokeLangGraphAgent = ({settings, agent, input, config}) ->
  unless settings?
    throw new Meteor.Error 'invokeLangGraphAgent', 'No settings provided'
  unless agent?
    throw new Meteor.Error 'invokeLangGraphAgent', 'No agent provided'
  unless input?
    throw new Meteor.Error 'invokeLangGraphAgent', 'No input provided'
  sdk = new LangGraphSDK.Client(settings)
  thread = await sdk.threads.create()
  
  # Prepare the run parameters
  runParams = {input}
  if config?
    runParams.config = {configurable: config}
  
  run = await sdk.runs.create thread.thread_id, agent, runParams
  await sdk.runs.join thread.thread_id, run.run_id
  await sdk.runs.get thread.thread_id, run.run_id
  state = await sdk.threads.getState thread.thread_id
  state.values
