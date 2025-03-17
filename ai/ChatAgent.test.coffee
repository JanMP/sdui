# ai/ChatAgent.test.coffee
import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'

import chai, {expect} from 'chai'
import chaiAsPromised from 'chai-as-promised'
chai.use chaiAsPromised

import {AIMessage} from '@langchain/core/messages'

import {run} from './ChatAgent'

describe 'run', ->
  it 'should return placeholder string', ->
    @timeout 30000
    expect(run()).to.eventually.equal 'fnord'
    # console.log (await result).content
