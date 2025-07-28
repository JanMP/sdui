import {LongTextField, Schema} from 'meteor/janmp:sdui'

import {createGeneratedArticlesTableAPI} from './GeneratedArticles.coffee'
import {createPromptsTableAPI} from './Prompts.coffee'
import {createResearchedArticlesTableAPI} from './ResearchedArticles.coffee'
import {createRssFeedsTableAPI} from './RssFeeds.coffee'
import {createMethods} from './createMethods.coffee'


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

export createRedakteurAPI = ({
sourceName
viewTableRole
editRole
articleCategories = defaultArticleCategories
articleGenerationSchemaDefinition
articleGenerationMainPrompt
publishGeneratedArticle = defaultPublishGeneratedArticle
retentionDays = 21
}) ->

  unless articleGenerationSchemaDefinition?
    throw new Error 'articleGenerationSchemaDefinition is required'

  unless articleGenerationMainPrompt?
    throw new Error 'articleGenerationMainPrompt is required'

  articleGenerationSchema = new Schema articleGenerationSchemaDefinition


  generatedArticlesDataOptions = createGeneratedArticlesTableAPI {sourceName, viewTableRole, editRole}
  promptsDataOptions = createPromptsTableAPI {sourceName, viewTableRole, editRole, articleCategories}
  researchedArticlesDataOptions = createResearchedArticlesTableAPI {sourceName, viewTableRole, editRole}
  rssFeedsDataOptions = createRssFeedsTableAPI {sourceName, viewTableRole, editRole}

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
  }

  {
    generatedArticlesDataOptions
    promptsDataOptions
    researchedArticlesDataOptions
    rssFeedsDataOptions
    creationParamsSchema
  }
