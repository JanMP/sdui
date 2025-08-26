import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {createTableDataAPI, Schema} from 'meteor/janmp:sdui'

export createResearchedArticlesStatisticsTableAPI = ({sourceDataOptions}) ->

  sourceSchema = sourceDataOptions.sourceSchema
  listSchema = new Schema
    type: 'object'
    properties:
      _id: type: 'string'
      feedName: type: 'string'
      count: type: 'integer'
      countUsable: type: 'integer'
      percentageUsable: type: 'number'
      avgContentLength: type: 'number'
      avgContentSnippetLength: type: 'number'

  getProcessorPipeline = -> [
    $group:
      _id: "$feedMetaData.title"
      feedName: $first: "$feedMetaData.title"
      count:
        $sum: 1
      countUsable:
        $sum:
          $cond: ["$usable", 1, 0]
      avgContentLength:
        $avg:
          $strLenCP: "$content"
      avgContentSnippetLength:
        $avg:
          $strLenCP: "$contentSnippet"
  ,
    $addFields:
      percentageUsable:
        $round: [
          $multiply: [
            $divide: ["$countUsable", "$count"]
            100
          ]
          0
        ]
      avgContentLength:
        $round: ["$avgContentLength", 0]
      avgContentSnippetLength:
        $round: ["$avgContentSnippetLength", 0]
  ]

  createTableDataAPI
    sourceName: "#{sourceDataOptions.sourceName}.byRssFeed"
    collection: sourceDataOptions.collection
    sourceSchema: sourceSchema
    listSchema: listSchema
    getProcessorPipeline: getProcessorPipeline
    initialSortColumn: "count"
    initialSortDirection: "DESC"
