import {Meteor} from 'meteor/meteor'
import {Mongo} from 'meteor/mongo'
import {Schema} from '../schema/Schema.coffee'
import {FilesCollection} from 'meteor/ostrio:files'
import {createTableDataAPI} from '../api/createTableDataAPI.coffee'

export class FilesTableApi
  constructor: ({sourceName}) ->
    @sourceName = sourceName
    @filesCollection = @createFilesCollection()
    @dataOptions = @createTableDataAPI()

  createFilesCollection: ->
    new FilesCollection
      collectionName: "#{@sourceName}.files"
      # allowClientCode: false
      # onBeforeUpload: (file) ->
      #   return true if file.size > 1024 * 1024 * 10 and /png|jpg|jpeg/i.test file.extension
      #   "Please upload image < 10MB"

  createTableDataAPI: -> {fnord: 'snafu'}