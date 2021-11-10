import getColumnsToExport from '../common/getColumnsToExport'
import _ from 'lodash'

export default createDefaultPipeline = ({getPreSelectPipeline, getProcessorPipeline, listSchema}) ->

  getPreSelectPipeline ?= -> []
  getProcessorPipeline ?= -> []

  searchPipeline = ({search}) ->
    if search? and search isnt ''
      keys = listSchema._firstLevelSchemaKeys.filter (key) -> not listSchema._schema[key].autotable?.hide
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
  
  defaultGetRowsPipeline = ({search, query = {}, sort = {_id: 1}, limit = 100, skip = 0}) ->
    [getPreSelectPipeline()...,
    {$match: query},
    getProcessorPipeline()...,
    (searchPipeline {search})...,
    {$sort: sort}, {$skip: skip}, {$limit: limit}]
  
  defaultGetRowCountPipeline = ({search, query = {}}) ->
    [getPreSelectPipeline()...,
    {$match: query}, getProcessorPipeline()..., (searchPipeline {search})...,
    {$count: 'count'}, $addFields: _id: "count"]

  defaultGetExportPipeline = ({search, query = {}, sort = {_id: 1}}) ->
    [getPreSelectPipeline()...,
    {$match: query}, getProcessorPipeline()..., (searchPipeline {search})...,
    {$sort: sort}, projectStage]

  {defaultGetRowsPipeline, defaultGetRowCountPipeline, defaultGetExportPipeline}