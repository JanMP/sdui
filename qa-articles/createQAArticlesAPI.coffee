import {getEmbedding} from '../common/getEmbedding.coffee'
import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import SimpleSchema from 'simpl-schema'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {createTableDataAPI, currentUserMustBeInRole, LongTextField} from 'meteor/janmp:sdui'
import _ from 'lodash'

sourceSchemaDefinition =
  question:
    type: String
    label: 'Frage'
    uniforms: LongTextField
  answer:
    type: String
    label: 'Antwort'
    uniforms: LongTextField
  vector:
    type: Array
    label: 'Vector'
  'vector.$':
    type: Number

