import {Mongo} from 'meteor/mongo'
import {createTableDataAPI, LongTextField, Schema, setupChatModel, generateUUID} from 'meteor/janmp:sdui'
import _ from 'lodash'

import {articleCategories, articleToPromptTag, dataOptions as researchedArticlesDataOptions} from './ResearchedArticles.coffee'

###*
  This file defines the GeneratedArticles collection and its API.
  This is just a wrapper around the createTableDataAPI function to create a table for GeneratedArticles.
  @param {Object} options - Options for the API.
  @param {String} options.sourceName - the sdui sourceName
  @param {Object} options.viewTableRole - the role for viewing the table
  @param {Schema} options.articleGenerationSchema - the schema for article generation
  @returns {Object} - the sdui createTableDataAPI dataOptions
  ###
export createGeneratedArticlesTableAPI = ({sourceName, viewTableRole, articleGenerationSchema}) ->

  GeneratedArticles = new Mongo.Collection "#{sourceName}.generatedArticles"

  # we set up a schema that sets some standard fields for the
  # articles list and keeps the generated article data in rawOutput
  sourceSchema = new Schema
    type: 'object'
    properties:
      title: type: 'string'
      teaser: type: 'string'
      content: type: 'string'
      createdAt:
        type: 'object'
        instanceof: 'Date'
      basedOnArticleId: type: 'string'
      published: type: 'boolean'
      rawOutput: articleGenerationSchema._schema
      articleLinks:
        type: 'array'
        items:
          type: 'object'
          properties:
            title: type: 'string'
            url: type: 'string'
      context:
        type: 'string'


  listSchema = sourceSchema.pick ['title', 'teaser', 'createdAt', 'published']
  formSchema = articleGenerationSchema

  createTableDataAPI
    sourceName: "#{sourceName}.generatedArticles"
    sourceSchema: sourceSchema
    listSchema: listSchema
    formSchema: formSchema
    collection: GeneratedArticles
    viewTableRole: viewTableRole
    canEdit: false
    canAdd: true
    initialSortColumn: 'createdAt'
    initialSortDirection: 'DESC'
    usePubSub: true
    perLoad: 50