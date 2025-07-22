import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {Schema} from 'meteor/janmp:sdui'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {createTableDataAPI} from 'meteor/janmp:sdui'
import _ from 'lodash'

###*
  This file defines the RssFeeds collection and its API.
  This is just a wrapper around the createTableDataAPI function to create a table for RssFeeds.
  @param {Object} options - Options for the API.
  @param {string} options.sourceName - the sdui sourceName
  @param {Object} options.viewTableRole - the role that can view the table
  @returns {Object} - the sdui createTableDataAPI dataOptions
  ###
export createRssFeedsTableAPI = ({sourceName, viewTableRole, editRole}) ->
  RssFeeds = new Mongo.Collection "#{sourceName}.rssfeeds"

  sourceSchema = new Schema
    type: 'object'
    properties:
      title:
        title: 'Titel'
        type: 'string'
        uniforms: label: 'Titel'
      url: type: 'string'
      description:
        title: 'Beschreibung'
        type: 'string'
      use:
        title: 'RSS Feed verwenden'
        type: 'boolean'
      useWithoutCorroboration:
        title: 'Erlaube Artikel ohne Bestätigung'
        type: 'boolean'
      trustScore:
        title: 'Vertrauenswürdigkeit'
        type: 'integer'
        minimum: 0
        maximum: 100
    required: ['title', 'url', 'description', 'use', 'trustScore']


  createTableDataAPI
    sourceName: "#{sourceName}.rssfeeds"
    sourceSchema: sourceSchema
    collection: RssFeeds
    viewTableRole: viewTableRole
    editRole: editRole
    canEdit: true
    canAdd: true
    canDelete: true
    initialSortColumn: 'title'
    initialSortDirection: 'ASC'
    usePubSub: true
