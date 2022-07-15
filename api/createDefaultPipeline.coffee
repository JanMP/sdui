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


  getQueryEditorPipeline = ({queryUiObject}) -> [$match: queryUiObjectToQuery {queryUiObject}]

  projectStage =
    $project:
      _(getColumnsToExport schema: listSchema)
      .keyBy (key) -> key
      .mapValues -> 1
      .value()

  defaultGetRowsPipeline = ({pub, search, query = {}, queryUiObject, sort = {_id: 1}, limit = 100, skip = 0}) ->
    [
      getPreSelectPipeline({pub})...,
      {$match: query},
      getProcessorPipeline({pub})...,
      getQueryEditorPipeline({queryUiObject})...
      (searchPipeline {search})...,
     {$sort: sort}, {$skip: skip}, {$limit: limit}
    ]

  defaultGetRowCountPipeline = ({pub, search, query = {}, queryUiObject}) ->
    [
      getPreSelectPipeline({pub})...,
      {$match: query},
      getProcessorPipeline({pub})...,
      getQueryEditorPipeline({queryUiObject})...
      (searchPipeline {search})...,
      {$count: 'count'},
      $addFields: _id: "count"
    ]


  defaultGetExportPipeline = ({search, query = {}, queryUiObject,  sort = {_id: 1}}) ->
    [
      getPreSelectPipeline()...,
      {$match: query},
      getProcessorPipeline()...,
      getQueryEditorPipeline({queryUiObject})...
      (searchPipeline {search})...,
    {$sort: sort}, projectStage]

  {defaultGetRowsPipeline, defaultGetRowCountPipeline, defaultGetExportPipeline}