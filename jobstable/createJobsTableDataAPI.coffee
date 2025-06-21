import {Meteor} from 'meteor/meteor'
import {Accounts} from 'meteor/accounts-base'
import {Schema} from 'meteor/janmp:sdui'
import {createTableDataAPI} from '../api/createTableDataAPI.coffee'
import {currentUserMustBeInRole} from '../common/roleChecks.coffee'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {Jobs} from 'meteor/msavin:sjobs'
import _ from 'lodash'

export createJobsTableDataAPI = ->

  sourceSchema = new Schema
    type: 'object'
    properties:
      name:
        title: 'Name'
        type: 'string'
      created:
        title: 'Created'
        instanceof: 'Date'
      due:
        title: 'Fällig'
        instanceof: 'Date'
      state:
        title: 'Status'
        type: 'string'
        enum: ['waiting', 'running', 'done', 'error']
      priority:
        title: 'Priorität'
        type: 'integer'
        minimum: 0
        maximum: 10

  new ValidatedMethod
    name: 'jobs.stop'
    validate: sourceSchema.methodValidator
    run: (job) ->
      currentUserMustBeInRole 'admin'
      console.log 'Jobs: ', Jobs.jobs
      Jobs.stop job.name

  new ValidatedMethod
    name: 'jobs.execute'
    validate: sourceSchema.methodValidator
    run: (job) ->
      currentUserMustBeInRole 'admin'
      console.log 'Jobs: ', Jobs.jobs
      Jobs.execute job.name

  new ValidatedMethod
    name: 'jobs.remove'
    validate: sourceSchema.methodValidator
    run: (job) ->
      currentUserMustBeInRole 'admin'
      console.log 'Jobs: ', Jobs.jobs
      Jobs.remove job.name


  createTableDataAPI
    sourceName: 'jobs'
    collection: Jobs?.collection
    sourceSchema: sourceSchema
    initialSortColumn: 'due'
    initialSortDirection: 'ASC'

