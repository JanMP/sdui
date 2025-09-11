import {LongTextField, Schema, SdWorkspaceAPI} from 'meteor/janmp:sdui'

import {createGeneratedArticlesTableAPI} from './GeneratedArticles.coffee'
import {createPromptsTableAPI} from './Prompts.coffee'
import {createResearchedArticlesTableAPI} from './ResearchedArticles.coffee'
import {createRssFeedsTableAPI} from './RssFeeds.coffee'
import {createMethods} from './createMethods.coffee'
import {createResearchedArticlesStatisticsTableAPI} from './ResearchedArticlesStatistics.coffee'

defaultPublishGeneratedArticle = ({data}) ->
  console.log 'Default publishGeneratedArticle called with data:', data
  # This is a placeholder function that is called by the publish method.
  # In practice it should e.g. just do a fetch to a specific endpoint and send the data.
  # The Method takes care of the data loading and marking the article as published.

defaultArticleCategories = [
  'News'
  'Howto'
  'Review'
  'Other'
]

###*
  Creates the Redakteur API with the given options.
  @param {Object} options - Options for the API.
  @param {String} options.sourceName - the sdui sourceName
  @param {Object} options.viewTableRole - the role for viewing the table
  @param {Object} options.editRole - the role for editing the table
  @param {Object} options.agentRole - the role for agent operations
  @param {Array} [options.articleCategories] - the article categories to use
  @param {Schema} options.articleGenerationSchema - the schema for article generation
  @param {String} options.articleGenerationMainPrompt - the main prompt for article generation
  @param {Boolean|Function} [options.publishGeneratedArticle] - function to publish generated articles, defaults to a no-op function
  @param {Number} [options.retentionDays] - number of days to retain generated articles, defaults to 21 days
  @param {Function} [options.createJobsSchedule] - function to create the jobs schedule
  @returns {Object} - the created Redakteur API
  ###
export createRedakteurAPI = ({
sourceName
viewTableRole
editRole
agentRole
articleCategories = defaultArticleCategories
articleGenerationSchema
articleGenerationMainPrompt
publishGeneratedArticle = defaultPublishGeneratedArticle
retentionDays = 21
createJobsSchedule
}) ->

  unless sourceName?
    throw new Error 'sourceName is required'
  unless viewTableRole?
    throw new Error 'viewTableRole is required'
  unless editRole?
    throw new Error 'editRole is required'
  unless agentRole?
    throw new Error 'agentRole is required'
  unless articleGenerationSchema?
    throw new Error 'articleGenerationSchema is required'

  unless articleGenerationMainPrompt?
    throw new Error 'articleGenerationMainPrompt is required'

  createJobsSchedule ?= ->
    in: days: 1
    on:
      hour: 6
      minute: 0

  generatedArticlesDataOptions = createGeneratedArticlesTableAPI {sourceName, viewTableRole, articleGenerationSchema}
  promptsDataOptions = createPromptsTableAPI {sourceName, viewTableRole, editRole, articleCategories}
  researchedArticlesDataOptions = createResearchedArticlesTableAPI {sourceName, viewTableRole, editRole}
  rssFeedsDataOptions = createRssFeedsTableAPI {sourceName, viewTableRole, editRole}
  researchedArticlesStatisticsDataOptions = createResearchedArticlesStatisticsTableAPI {sourceDataOptions: researchedArticlesDataOptions}
  workspaceApi = new SdWorkspaceAPI sourceDataOptions: generatedArticlesDataOptions

  # schema for the add generatedArticle form
  creationParamsSchema = new Schema
    type: 'object'
    properties:
      prompt:
        type: 'string'
        title: 'Anweisungen zum Schreiben des Artikels'
        uniforms:
          component: LongTextField
          rows: 15
          cols: 60
      articleType:
        type: 'string'
        enum: articleCategories

  createMethods {
    sourceName
    viewTableRole
    editRole
    articleCategories
    articleGenerationSchema
    articleGenerationMainPrompt
    retentionDays
    creationParamsSchema
    generatedArticlesDataOptions
    promptsDataOptions
    researchedArticlesDataOptions
    rssFeedsDataOptions
    publishGeneratedArticle
    createJobsSchedule
  }

  {
    generatedArticlesDataOptions
    promptsDataOptions
    researchedArticlesDataOptions
    researchedArticlesStatisticsDataOptions
    rssFeedsDataOptions
    creationParamsSchema
    workspaceApi
  }
