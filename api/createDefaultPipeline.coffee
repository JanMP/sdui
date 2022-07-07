import {getColumnsToExport} from '../common/getColumnsToExport.coffee'
import _ from 'lodash'

export createDefaultPipeline = ({getPreSelectPipeline, getProcessorPipeline, listSchema}) ->

  getPreSelectPipeline ?= ({pub}) -> []
  getProcessorPipeline ?= ({pub}) -> []

  searchPipeline = ({search}) ->
    if search? and search isnt ''
      keys = listSchema._firstLevelSchemaKeys.filter (key) -> not listSchema._schema[key].sdTable?.hide
      fieldSearches = keys.map (key) ->
        switch listSchema.getQuickTypeForKey key
          when 'string', 'stringArray'
            "#{key}":
              $regex: search
              $options: 'i'
          when 'number'
            $expr:
              $regexMatch:
                input: $toString: "$#{key}"
                regex: search
                options: 'i'
          when 'numberArray'
            $and: [
              "#{key}": $exists: true
            ,
              $expr:
                $anyElementTrue:
                  $map:
                    input: "$#{key}"
                    in:
                      $regexMatch:
                        input: $toString: '$$this'
                        regex: search
                        options: 'i'
            ]
          else null
      [$match: $or: _.compact fieldSearches]
    else
      []


  projectStage =
    $project:
      _(getColumnsToExport schema: listSchema)
      .keyBy (key) -> key
      .mapValues -> 1
      .value()
  
  defaultGetRowsPipeline = ({pub, search, query = {}, sort = {_id: 1}, limit = 100, skip = 0}) ->
    [
      getPreSelectPipeline({pub})...,
      getProcessorPipeline({pub})...,
      {$match: query},
      (searchPipeline {search})...,
     {$sort: sort}, {$skip: skip}, {$limit: limit}
    ]
  
  defaultGetRowCountPipeline = ({pub, search, query = {}}) ->
    [
      getPreSelectPipeline({pub})...,
      getProcessorPipeline({pub})...,
      {$match: query},
      (searchPipeline {search})...,
      {$count: 'count'},
      $addFields: _id: "count"
    ]

  defaultGetExportPipeline = ({search, query = {}, sort = {_id: 1}}) ->
    [getPreSelectPipeline()...,
    {$match: query}, getProcessorPipeline()..., (searchPipeline {search})...,
    {$sort: sort}, projectStage]

  {defaultGetRowsPipeline, defaultGetRowCountPipeline, defaultGetExportPipeline}