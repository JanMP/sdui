import {Meteor} from 'meteor/meteor'
import SimpleSchema from 'simpl-schema'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {S3, ListObjectsCommand, PutObjectCommand} from '@aws-sdk/client-s3'
import {getSignedUrl} from '@aws-sdk/s3-request-presigner'
import {currentUserMustBeInRole} from '../common/roleChecks.coffee'

export filesAPISourceSchema =
  new SimpleSchema
    key:
      type: String
    name:
      type: String
    owner:
      type: String
    size:
      type: Number
    type:
      type: String
      optional: true
    status:
      type: String
      allowedValues: ['upload-requested', 'upload-done', 'upload-not-ok', 'fetched']
    fetchDate:
      type: Date
      optional: true

export createFilesAPI = ({sourceName, collection, userFilesRole, uploadCommonRole, getCommonFileListRole, getAllFileListRole}) ->


  unless sourceName?
    throw new Error 'no sourceName given'

  unless collection?
    throw new Error 'no collection given'

  unless userFilesRole?
    userFilesRole = 'username-is-admin'
    console.warn "[createFilesAPI #{sourceName}]:
      no userfilesRole defined, using username-is-admin"

  unless uploadCommonRole?
    uploadCommonRole = 'username-is-admin'
    console.warn "[createFilesAPI #{sourceName}]:
      no uploadCommonRole defined, using username-is-admin"

  unless getCommonFileListRole?
    getCommonFileListRole = 'username-is-admin'
    console.warn "[createFilesAPI #{sourceName}]:
      no getCommonFileListRole defined, using username-is-admin"

  unless getAllFileListRole?
    getAllFileListRole = 'username-is-admin'
    console.warn "[createFilesAPI #{sourceName}]:
      no getAllFileListRole defined, using username-is-admin"

  if Meteor.isServer
    unless (s = Meteor.settings[sourceName])?
      throw new Error "Meteor.settings: missing key #{sourceName}"
    
    bucket = s.bucket

    s3Client =
      new S3
        endpoint: s.endpoint
        region: s.region
        credentials:
          accessKeyId: s.accessKeyId
          secretAccessKey: s.secretAccessKey


    getFileList = (prefix) ->
      s3Client
        .send new ListObjectsCommand
          Bucket: bucket
          Prefix: prefix
        .then (data) ->
          console.log data
          data.Contents?.map (c) ->
            key: c.Key
            size: c.Size

    updateFilesCollection = ->
      getFileList()
        .then (files) ->
          fetchDate = new Date()
          files.forEach (file) ->
            console.log file
            unless (owner = file.key.match?(/^(.+?)(?=\/)/g)?[0]) is 'common'
              unless owner? and Meteor.users.findOne _id: owner
                owner = 'unknown-owner'
            
            name = /^.+?\/(.+)/g.exec(file.key)?[1] ? file.key

            collection.upsert {key: file.key},
              $set:
                key: file.key
                name: name
                owner: owner
                size: file.size
                status: 'fetched'
                fetchDate: fetchDate


    getUploadUrl = ({key, type}) ->
      getSignedUrl s3Client,
        new PutObjectCommand
          Bucket: bucket
          Key: key
          ContentType: type
      ,
        expiresIn: 15 * 60

  new ValidatedMethod
    name: "#{sourceName}.getFileList"
    validate: ->
    run: ->
      if Meteor.isServer
        updateFilesCollection()

        
  new ValidatedMethod
    name: "#{sourceName}.requestUpload"
    validate:
      new SimpleSchema
        name: String
        size: Number
        type: String
        saveAsCommon:
          type: Boolean
          optional: true
      .validator()
    run: ({name, size, type, saveAsCommon}) ->
      if saveAsCommon
        currentUserMustBeInRole uploadCommonRole
      else
        currentUserMustBeInRole userFilesRole
      if Meteor.isServer
        prefix = if saveAsCommon then 'common/' else "#{Meteor.userId()}/"
        key = prefix + name
        getUploadUrl {key, type}
          .then (uploadUrl) ->
            collection.upsert {key},
              key: key
              name: name
              owner: Meteor.userId()
              size: size
              type: type
              status: 'requested'
            {uploadUrl, key}

        

  new ValidatedMethod
    name: "#{sourceName}.finishUpload"
    validate:
      new SimpleSchema
        key:
          type: String
        statusText:
          type: String
      .validator()
    run: ({key, statusText}) ->
      if key.startsWith 'common/'
        currentUserMustBeInRole uploadCommonRole
      if key.startsWith "#{Meteor.userId()}/"
        currentUserMustBeInRole userFilesRole
      console.log {key, statusText}
      if Meteor.isServer
        status = if statusText is 'OK' then 'upload-done' else 'upload-not-ok'
        collection.update {key}, $set: {status}

  {sourceName, collection}

