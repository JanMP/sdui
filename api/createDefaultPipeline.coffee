import {getColumnsToExport} from '../common/getColumnsToExport.coffee'
import processSearchInput from '../common/processSearchInput.coffee'
import queryUiObjectToQuery from '../query-editor/queryUiObjectToQuery.coffee'


import _ from 'lodash'


export createDefaultPipeline = ({getPreSelectPipeline, getProcessorPipeline, listSchema, queryEditorSchema}) ->

  getPreSelectPipeline ?= ({pub}) -> []
  getProcessorPipeline ?= ({pub}) -> []

  queryEditorSchema ?= listSchema

  searchPipeline = ({search, knnIdsAndScore}) ->
    unless search? or search is ''
      return []

    {isValidRegEx, flags, processedString} = processSearchInput search

    parts = if isValidRegEx then [] else (_.compact processedString.split ' ') ? []
    regexOptions = if isValidRegEx then flags else 'i'


    generateQueryPart = (op) ->
      if parts.length > 1
        $and: parts.map op
      else op processedString

    keys = queryEditorSchema._firstLevelSchemaKeys.filter (key) -> not queryEditorSchema._schema[key].sdTable?.hide
    fieldSearches = keys.map (key) ->
      switch queryEditorSchema.getQuickTypeForKey key
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
    
    knnMatch = if knnIdsAndScore.length then _id: $in: knnIdsAndScore.map (row) -> row._id
    
    [$match: $or: _.compact [knnMatch, fieldSearches...]]


  getQueryEditorPipeline = ({queryUiObject}) -> [$match: queryUiObjectToQuery {queryUiObject}]

  projectStage =
    $project:
      _(getColumnsToExport schema: listSchema)
      .keyBy (key) -> key
      .mapValues -> 1
      .value()

  addKnnScoresPipeline = (knnIdsAndScore) ->
    if knnIdsAndScore.length
      [
        $addFields: {knnIdsAndScore}
      ,
        $addFields: knnScore: $arrayElemAt: ['$knnIdsAndScore.score', $indexOfArray: ['$knnIdsAndScore._id', '$_id']]
      ,
        $unset: 'knnIdsAndScore'
      ]
    else []

  defaultGetRowsPipeline = ({pub, search, knnIdsAndScore = [], query = {},
    queryUiObject, sort = {_id: 1}, limit = 100, skip = 0}) ->
      _.compact [
        getPreSelectPipeline({pub})...
        {$match: query}
        getProcessorPipeline({pub})...
        getQueryEditorPipeline({queryUiObject})...
        (searchPipeline {search, knnIdsAndScore})...
        projectStage
        (addKnnScoresPipeline knnIdsAndScore)...
      {$sort: sort}, {$skip: skip}, {$limit: limit}
      ]

  defaultGetRowCountPipeline = ({pub, search, knnIdsAndScore = [], query = {}, queryUiObject}) ->
    [
      getPreSelectPipeline({pub})...,
      {$match: query},
      getProcessorPipeline({pub})...,
      getQueryEditorPipeline({queryUiObject})...
      (searchPipeline {search, knnIdsAndScore})...,
      {$count: 'count'},
      $addFields: _id: "count"
    ]


  defaultGetExportPipeline = ({search, knnIdsAndScore = [], query = {}, queryUiObject,  sort = {_id: 1}}) ->
    [
      getPreSelectPipeline()...,
      {$match: query},
      getProcessorPipeline()...,
      getQueryEditorPipeline({queryUiObject})...
      (searchPipeline {search, knnIdsAndScore})...,
    {$sort: sort}, projectStage]

  {defaultGetRowsPipeline, defaultGetRowCountPipeline, defaultGetExportPipeline}