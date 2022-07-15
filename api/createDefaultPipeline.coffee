import {getColumnsToExport} from '../common/getColumnsToExport.coffee'
import processSearchInput from '../common/processSearchInput.coffee'
import queryUiObjectToQuery from '../query-editor/queryUiObjectToQuery.coffee'


import _ from 'lodash'


export createDefaultPipeline = ({getPreSelectPipeline, getProcessorPipeline, listSchema}) ->

  getPreSelectPipeline ?= ({pub}) -> []
  getProcessorPipeline ?= ({pub}) -> []

  searchPipeline = ({search}) ->
    unless search? or search is ''
      return []

    {isValidRegEx, flags, processedString} = processSearchInput search

    console.log 'search', {isValidRegEx, flags, processedString}

    parts = if isValidRegEx then [] else (_.compact processedString.split ' ') ? []
    regexOptions = if isValidRegEx then flags else 'i'


    generateQueryPart = (op) ->
      if parts.length > 1
        $and: parts.map op
      else op processedString

    keys = listSchema._firstLevelSchemaKeys.filter (key) -> not listSchema._schema[key].sdTable?.hide
    fieldSearches = keys.map (key) ->
      switch listSchema.getQuickTypeForKey key
        when 'string', 'stringArray'
          generateQueryPart (part) ->
            "#{key}":
              $regex: part
              $options: regexOptions
        when 'number'
          generateQueryPart (part) ->
            $expr:
              $regexMatch:
                input: $toString: "$#{key}"
                regex: part
                options: regexOptions
        when 'numberArray'
          generateQueryPart (part) ->
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
                        regex: part
                        options: regexOptions
              ]
        else null

    [$match: $or: _.compact fieldSearches]



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