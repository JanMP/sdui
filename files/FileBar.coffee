import React, {useState} from 'react'
import {meteorApply} from '../common/meteorApply.coffee'
import {toast} from 'react-toastify'
import {SdList} from '../tables/SdList.coffee'


ListItemContent  = ({rowData}) ->
  <div className="flex p-2 gap-2">
    <div className="h-[60px]">
     { <img className="max-h-full max-w-[80px]" src={rowData.url} alt="image" /> if rowData.status is 'ok'}
    </div>

    <div>
      <div className="text-lg">{rowData.name}</div>
      <div className="text-sm">{rowData.size}</div>
    </div>
    
  </div>

export FileBar = ({dataOptions}) ->
  {sourceName, collection} = dataOptions

  [showUpload, setShowUpload] = useState false
  toggleShowUpload = -> setShowUpload (x) -> not x

  send = (e) ->
    if (file = document.getElementById('file-input')?.files?[0])?
      {name, size, type} = file
      console.log "filename: #{name}"
      meteorApply
        method: "#{sourceName}.requestUpload"
        data: {name, size, type}
      .then ({uploadUrl, key}) ->
        response =
          await fetch uploadUrl,
            method: 'PUT'
            headers:
              'Content-Type': type
              'x-amz-acl': 'public-read'
            body: file
        {response, key}
      .then ({response, key}) ->
        meteorApply
          method: "#{sourceName}.finishUpload"
          data:
            key: key
            statusText: response.statusText
      .catch (error) ->
        console.error error
        toast.error "#{error}"

  onFileInputChange = (e) ->
    if (file = e.target.files?[0])?
      console.log file
    
  updateFileList = ->
    console.log {sourceName}
    meteorApply
      method: "#{sourceName}.updateFilesCollection"
      data: {}
    .then console.log

  <div className="m-1 p-2">
    {<div className="border border-blue-500 h-[500px]">
      <SdList dataOptions={dataOptions} customComponents={{ListItemContent}}/>
    </div> if true}
    {<div className="border border-red-500">
      <input id="file-input" type="file" onChange={onFileInputChange}/>
      <button onClick={send}>send</button>
    </div> if showUpload}
    <div>
      <button onClick={toggleShowUpload}>toggle upload</button>
      <button onClick={updateFileList}>update filelist</button>
    </div>
  </div>