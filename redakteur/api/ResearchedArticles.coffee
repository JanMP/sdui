import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {createTableDataAPI, generateUUID, Schema, setupChatModel} from 'meteor/janmp:sdui'
import {getEmbedding} from './getEmbedding.coffee'
import RSSParser from 'rss-parser'
import {tool} from '@langchain/core/tools'
import {HumanMessage, AIMessage, SystemMessage} from '@langchain/core/messages'
import {ChatOpenAI} from '@langchain/openai'
import {ChatAnthropic} from '@langchain/anthropic'
import {z} from 'zod'
import {RssFeeds} from './RssFeeds.coffee'
import _ from 'lodash'
import {writeArticleWithContext} from './GeneratedArticles.coffee'
import {Prompts} from './Prompts.coffee'

###*
  This file defines the ResearchedArticles collection and its API.
  This is just a wrapper around the createTableDataAPI function to create a table for ResearchedArticles.
  @param {Object} options - Options for the API.
  @param {string} options.sourceName - the sdui sourceName
  @returns {Object} - the sdui createTableDataAPI dataOptions
  ###
export createResearchedArticlesTableAPI = ({sourceName, viewTableRole, editRole}) ->

  ResearchedArticles = new Mongo.Collection "#{sourceName}.researchedArticles"

  sourceSchema = new Schema
    type: 'object'
    properties:
      uuid: type: 'string'
      title: type: 'string'
      link: type: 'string'
      contentSnippet: type: 'string'
      content:
        type: 'string'
        sdContent: isContent: true
      pubDate:
        instanceof: 'Date'
      feedMetaData:
        type: 'object'
        properties:
          title:
            type: 'string'
            uniforms: label: 'Titel'
          url: type: 'string'
          description:
            type: 'string'
            uniforms: label: 'Beschreibung'
          use:
            type: 'boolean'
            uniforms: label: 'RSS Feed verwenden'
          trustScore:
            type: 'integer'
            minimum: 0
            maximum: 100
            uniforms: label: 'Vertrauenswürdigkeit'
      similarArticles:
        uniforms: label: 'Ähnliche Artikel'
        type : 'array'
        items:
          type: 'object'
          properties:
            _id: type: 'string'
            title: type: 'string'
            link: type: 'string'
            pubDate:
              instanceof: 'Date'
            score: type: 'number'
            feedMetaData:
              type: 'object'
              properties:
                title:
                  type: 'string'
                  uniforms: label: 'Titel'
                url: type: 'string'
                description:
                  type: 'string'
                  uniforms: label: 'Beschreibung'
                use:
                  type: 'boolean'
                  uniforms: label: 'RSS Feed verwenden'
                trustScore:
                  type: 'integer'
                  minimum: 0
                  maximum: 100
                  uniforms: label: 'Vertrauenswürdigkeit'
      used:
        type: 'boolean'
      usable:
        type: 'boolean'
      articleCategory:
        type: 'string'

  sdAiSettings =
    embeddingModelSettings: Meteor.settings.embeddingCP
    getEmbeddingContext: ({document}) ->
      """
        #{document.title}
        #{document.pubDate}
        #{document.content}
      """

  createTableDataAPI
    sourceName: "#{sourceName}.researchedArticles"
    sourceSchema: sourceSchema
    collection: ResearchedArticles
    viewTableRole: viewTableRole
    editRole: editRole
    canEdit: false
    initialSortColumn: 'pubDate'
    initialSortDirection: 'DESC'
    usePubSub: false
    perLoad: 50
    sdAiSettings: sdAiSettings
