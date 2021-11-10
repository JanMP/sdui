import chai from 'chai'
import deepEqualInAnyOrder from 'deep-equal-in-any-order'
chai.use deepEqualInAnyOrder
{expect} = chai

import SimpleSchema from 'simpl-schema'
import _ from 'lodash'

import createDefaultPipeline from './createDefaultPipeline'

# import importTestFaelle from '/imports/api/importTestFaelle'
# import {Faelle} from '/imports/api/Faelle'

#These Tests run on both client and server

listSchema = new SimpleSchema
  a: String
  b: Number
  c: [String]
  d: [Number]

describe "createDefaultPipeline", ->

  it "returns an object with two functions", ->
    {defaultGetRowsPipeline, defaultGetRowCountPipeline} =
      createDefaultPipeline {listSchema}
    
    expect(defaultGetRowsPipeline).to.be.a 'Function'
    expect(defaultGetRowCountPipeline).to.be.a 'Function'

  it "defaultGetRowsPipeline doesn't contain the search phase when search isn't given", ->
    {defaultGetRowsPipeline, defaultGetRowCountPipeline} =
      createDefaultPipeline {listSchema}

    pipeline = defaultGetRowsPipeline {}
    expect pipeline
    .to.eql [{$match: {}}, {$sort: {_id: 1}}, {$skip: 0}, {$limit: 100}]

  it "given a search string, defaultGetRowsPipeline produces a pipeline with a search phase", ->
    {defaultGetRowsPipeline, defaultGetRowCountPipeline} =
      createDefaultPipeline {listSchema}

    pipeline = defaultGetRowsPipeline search: 'x'
    expectedSearchPhase =
      $match:
        $or: [
          a:
            $regex: 'x'
            $options: 'i'
        ,
          $expr:
            $regexMatch:
              input: $toString: '$b'
              regex: 'x'
              options: 'i'
        ,
          c:
            $regex: 'x'
            $options: 'i'
        ,
          $and: [
            d: $exists: true
          ,
            $expr:
              $anyElementTrue:
                $map:
                  input: '$d'
                  in:
                    $regexMatch:
                      input: $toString: '$$this'
                      regex: 'x'
                      options: 'i'
          ]
        ]

    expect pipeline[1] #this is where the match phase for the search if there is no pipelineMiddle
    .to.deep.equalInAnyOrder expectedSearchPhase
      
      
