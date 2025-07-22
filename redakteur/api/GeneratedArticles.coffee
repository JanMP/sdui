import {Mongo} from 'meteor/mongo'
import {createTableDataAPI, LongTextField, Schema, setupChatModel, generateUUID} from 'meteor/janmp:sdui'
import _ from 'lodash'

import {articleCategories, articleToPromptTag, dataOptions as researchedArticlesDataOptions} from './ResearchedArticles.coffee'

###*
  This file defines the GeneratedArticles collection and its API.
  This is just a wrapper around the createTableDataAPI function to create a table for GeneratedArticles.
  @param {Object} options - Options for the API.
  @param {String} options.sourceName - the sdui sourceName
  @returns {Object} - the sdui createTableDataAPI dataOptions
  ###
export createGeneratedArticlesTableAPI = ({sourceName, viewTableRole}) ->

  GeneratedArticles = new Mongo.Collection "#{sourceName}.generatedArticles"

  sourceSchema = new Schema
    type: 'object'
    properties:
      title: type: 'string'
      teaser: type: 'string'
      content: type: 'string'
      createdAt: instanceof: 'Date'
      basedOnArticleId: type: 'string'
      published: type: 'boolean'
      rawOutput: type: 'object' # this contains all the generated data
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

  createTableDataAPI
    sourceName: "#{sourceName}.generatedArticles"
    sourceSchema: sourceSchema
    listSchema: listSchema
    collection: GeneratedArticles
    viewTableRole: viewTableRole
    canEdit: false
    canAdd: true
    initialSortColumn: 'createdAt'
    initialSortDirection: 'DESC'
    usePubSub: true
    perLoad: 50