import {Meteor} from 'meteor/meteor'
import SimpleSchema from 'simpl-schema'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {S3, ListObjectsCommand, PutObjectCommand, DeleteObjectCommand} from '@aws-sdk/client-s3'
import {getSignedUrl} from '@aws-sdk/s3-request-presigner'
import {currentUserMustBeInRole, currentUserIsInRole} from '../common/roleChecks.coffee'
import {createTableDataAPI} from './createTableDataAPI.coffee'
import {FileInput} from '../files/FileInput.coffee'

delay = (ms) -> new Promise (resolve) -> setTimeout resolve, ms

SimpleSchema.extendOptions ['sdTable', 'uniforms']

export sourceSchema =
  new SimpleSchema
    key:
      type: String
    name:
      type: String
    isCommon:
      type: Boolean
    uploader:
      type: String
    size:
      type: Number
    type:
      type: String
      optional: true
    url:
      type: String
    thumbnailUrl:
      type: String
      optional: true
    status:
      type: String
      allowedValues: ['requested', 'ok', 'not-ok']
    thumbnailStatus:
      type: String
      optional: true
      allowedValues: ['requested', 'ok', 'not-ok']
    fetchDate:
      type: Date
      optional: true

setupNewItem = ->
  files: []
  uploadAs: ''

export createFilesAPI = ({
sourceName, collection
getUserFileListRole, uploadUserFilesRole
getCommonFileListRole, uploadCommonFilesRole}) ->

  unless sourceName?
    throw new Error 'no sourceName given'

  unless collection?
    throw new Error 'no collection given'

  unless getUserFileListRole?
    getUserFileListRole = 'username-is-admin'
    console.warn "[createFilesAPI #{sourceName}]:
      no uploadCommonFilesRole defined, using username-is-admin"

  unless uploadUserFilesRole?
    uploadUserFilesRole = 'username-is-admin'
    console.warn "[createFilesAPI #{sourceName}]:
      no uploadUserFilesRole defined, using username-is-admin"

  unless getCommonFileListRole?
    getCommonFileListRole = 'username-is-admin'
    console.warn "[createFilesAPI #{sourceName}]:
      no getCommonFileListRole defined, using username-is-admin"

  unless uploadCommonFilesRole?
    uploadCommonFilesRole = 'username-is-admin'
    console.warn "[createFilesAPI #{sourceName}]:
      no uploadCommonFilesRole defined, using username-is-admin"

  makeDeleteMethodRunFkt = ({collection, transformIdToMongo, transformIdToMiniMongo}) ->
    ({id}) ->
      if Meteor.isServer
        entry = collection.findOne _id: id
        unless entry?
          throw new Meteor.Error "[#{sourceName}.delete] no entry #{id}"
        unless (key = entry.key)? and typeof key is 'string'
          throw new Meteor.Error "[#{sourceName}.delete] no key in entry #{id}"
        switch
          when key.startsWith 'common/'
            currentUserMustBeInRole 'uploadCommonFiles'
          when key.startsWith "#{Meteor.userId}/"
            currentUserMustBeInRole uploadUserFilesRole
          else
            currentUserMustBeInRole 'admin'
        keysToDelete = []
        if entry.status is 'ok'
          keysToDelete.push key
        if entry.thumbnailStatus is 'ok'
          keysToDelete.push key + '.thumbnail.png'
        Promise.allSettled keysToDelete.map (k) -> deleteObject key:k
        .then ->
          collection.remove _id: transformIdToMongo id
        .catch (error) -> throw new Meteor.Error error

  tableDataOptions = createTableDataAPI
    sourceName: sourceName
    sourceSchema: sourceSchema
    collection: collection
    viewTableRole: 'any'
    editRole: 'any'
    canEdit: false
    canAdd: true
    canDelete: true
    canSearch: true
    canExport: false
    setupNewItem: setupNewItem
    makeDeleteMethodRunFkt: makeDeleteMethodRunFkt

  if Meteor.isServer
    unless (settings = Meteor.settings[sourceName])?
      throw new Error "Meteor.settings: missing key #{sourceName}"
    
    {endpoint, region, accessKeyId, secretAccessKey, bucket, downloadURLRoot} = settings

    s3Client =
      new S3
        endpoint: endpoint
        region: region
        credentials:
          accessKeyId: accessKeyId
          secretAccessKey: secretAccessKey

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

    #TODO update this
    updateFilesCollection = ->
      getFileList()
        .then (files) ->
          fetchDate = new Date()
          files.forEach (file) ->
            unless (owner = file.key.match?(/^(.+?)(?=\/)/g)?[0]) is 'common'
              unless owner? and Meteor.users.findOne _id: owner
                owner = 'unknown-owner'
            name = /^.+?\/(.+)/g.exec(file.key)?[1] ? file.key
            collection.upsert {key: file.key},
              $set:
                key: file.key
                name: name
                uploader: owner
                size: file.size
                status: 'ok'
                url: downloadURLRoot + file.key
                fetchDate: fetchDate


    getUploadUrl = ({key, type}) ->
      getSignedUrl s3Client,
        new PutObjectCommand
          Bucket: bucket
          Key: key
          ContentType: type
          ACL: 'public-read'
      ,
        expiresIn: 15 * 60


    deleteObject = ({key}) ->
      s3Client
        .send new DeleteObjectCommand
          Bucket: bucket
          Key: key
        .then (result) ->
          unless result.DeleteMarker
            throw new Error "[could-not-delete #{key}]"


  new ValidatedMethod
    name: "#{sourceName}.updateFilesCollection"
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
        currentUserMustBeInRole uploadCommonFilesRole
      else
        currentUserMustBeInRole uploadUserFilesRole
      if Meteor.isServer
        prefix = if saveAsCommon then 'common/' else "#{Meteor.userId()}/"
        key = prefix + name
        getUploadUrl {key, type}
          .then (uploadUrl) ->
            originalKey = key.replace /\.thumbnail\.png$/, ''
            thumbnailKey = if key.endsWith '.thumbnail.png' then key
            collection.upsert {key: originalKey},
              $set:
                key: originalKey
                name: name unless thumbnailKey?
                isCommon: saveAsCommon
                uploader: Meteor.userId()
                size: size unless thumbnailKey?
                type: type unless thumbnailKey?
                url: downloadURLRoot + originalKey
                thumbnailUrl: if thumbnailKey? then downloadURLRoot + thumbnailKey
                status: 'requested' unless thumbnailKey?
                thumbnailStatus: 'requested' if thumbnailKey?
            {uploadUrl, key}
          .catch (error) -> throw error


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
      switch
        when key.startsWith 'common/'
          currentUserMustBeInRole uploadCommonFilesRole
        when key.startsWith "#{Meteor.userId()}/"
          currentUserMustBeInRole uploadUserFilesRole
        else
          throw new Meteor.Error "[#{sourceName}.finishUPload key not allowed]"
      console.log {key, statusText}
      if Meteor.isServer
        status = if statusText is 'OK' then 'ok' else 'not-ok'
        originalKey = key.replace /\.thumbnail\.png$/, ''
        thumbnailKey = if key.endsWith '.thumbnail.png' then key
        collection.update {key: originalKey},
          $set:
            if thumbnailKey?
              thumbnailStatus: status
            else
              status: status
  
  new ValidatedMethod
    name: "#{sourceName}.deleteObject"
    validate:
      new SimpleSchema
        key: String
      .validator()
    run: ({key}) ->
      switch
        when key.startsWith 'common/'
          currentUserMustBeInRole 'uploadCommonFiles'
        when key.startsWith "#{Meteor.userId}/"
          currentUserMustBeInRole uploadUserFilesRole
        else
          currentUserMustBeInRole 'admin'
      if Meteor.isServer
        entry = collection.findOne {key}
        unless entry?
          throw new Meteor.Error "[#{sourceName}.deleteObject] no entry for key: #{key}"
        keysToDelete = []
        if entry.status is 'ok'
          keysToDelete.push key
        if entry.thumbnailStatus is 'ok'
          keysToDelete.push key + '.thumbnail.png'
        Promise.allSettled keysToDelete.map (k) -> deleteObject key:k
        .then ->
          collection.remove _id: entry._id
        .catch (error) -> throw new Meteor.Error error

  roles = {getUserFileListRole, uploadUserFilesRole, getCommonFileListRole, uploadCommonFilesRole}
  #return
  {tableDataOptions, roles}
  

