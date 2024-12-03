import {Meteor} from 'meteor/meteor'
import {getColumnsToExport} from '../common/getColumnsToExport.coffee'
import processSearchInput from '../common/processSearchInput.coffee'
import _ from 'lodash'


(debugPipelines = Meteor.settings?.debugPipelines ? false)

export createDefaultPipeline = ({getPreSelectPipeline, getProcessorPipeline, listSchema}) ->

  getPreSelectPipeline ?= ({pub}) -> []
  getProcessorPipeline ?= ({pub}) -> []

  textSearchPipeline = ({search}) ->
    if (not search?) or search is ''
      return []

    {isValidRegEx, flags, processedString} = processSearchInput search

    parts = if isValidRegEx then [] else (_.compact processedString.split ' ') ? []
    regexOptions = if isValidRegEx then flags else 'i'


    generateQueryPart = (op) ->
      if parts.length > 1
        $and: parts.map op
      else op processedString

    keys = listSchema.firstLevelSchemaKeys.filter (key) -> not listSchema._schema.properties[key].sdTable?.hide
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
      # TODO: add support for search in object values
        else null

    [$match: $or: _.compact fieldSearches]


  projectStage =
    $project:
      _(getColumnsToExport schema: listSchema)
      .keyBy (key) -> key
      .mapValues -> 1
      .value()

  defaultGetRowsPipeline = ({pub, search, query = {}, sort = {_id: 1}, limit = 100, skip = 0}) ->
    _.compact [
      (await getPreSelectPipeline {pub})...,
      {$match: query},
      (await getProcessorPipeline {pub})...,
      (await textSearchPipeline {search})...,
      projectStage unless debugPipelines, # This is super important. Dont delete it by mistake again...
     {$sort: sort}, {$skip: skip}, {$limit: limit}
    ]


  defaultGetExportPipeline = ({search, query = {},  sort = {_id: 1}}) ->
    [
      (await getPreSelectPipeline())...,
      {$match: query},
      (await getProcessorPipeline())...,
      (await textSearchPipeline {search})...,
      {$sort: sort}, projectStage
    ]

  {defaultGetRowsPipeline, defaultGetExportPipeline}