import {LongTextField, Schema} from 'meteor/janmp:sdui'

import {createGeneratedArticlesTableAPI} from './GeneratedArticles.coffee'
import {createPromptsTableAPI} from './Prompts.coffee'
import {createResearchedArticlesTableAPI} from './ResearchedArticles.coffee'
import {createRssFeedsTableAPI} from './RssFeeds.coffee'
import {createMethods} from './createMethods.coffee'

import defaultArticleGenerationSchema from './articleGenerationSchema.JSON'
import defaultGenerateArticleMainPrompt from './generate-article-prompt.coffee'


defaultArticleCategories = [
  'News'
  'Howto'
  'Review'
  'Other'
]

export createRedakteurAPI = ({
sourceName
articleCategories = defaultArticleCategories
articleGenerationSchema = defaultArticleGenerationSchema
generateArticleMainPrompt = defaultGenerateArticleMainPrompt
retentionDays = 21
viewTableRole
editRole
}) ->

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
    generateArticleMainPrompt
    retentionDays
    creationParamsSchema
    generatedArticlesDataOptions
    promptsDataOptions
    researchedArticlesDataOptions
    rssFeedsDataOptions
  }

  {
    generatedArticlesDataOptions
    promptsDataOptions
    researchedArticlesDataOptions
    rssFeedsDataOptions
  }
