import React, {useState} from 'react'
import {meteorApply} from '../common/meteorApply.coffee'

FileSelector = ->
  <div className="border border-blue-500">
    FileSelector
  </div>

export FileBar = ->

  [showUpload, setShowUpload] = useState false
  toggleShowUpload = -> setShowUpload (x) -> not x
  [showFileSelector, setShowFileSelector] = useState false
  toggleFileSelector = -> setShowFileSelector (x) -> not x

  send = (e) ->
    if (file = document.getElementById('file-input')?.files?[0])?
      {name, size, type} = file
      console.log "filename: #{name}"
      meteorApply
        method: "spaces.getUploadUrl"
        data: {name, size, type}
      .then (url) ->
        fetch url,
          method: 'PUT'
          headers: 'Content-Type': type
          body: file
      .then console.log
      .catch console.error

  onFileInputChange = (e) ->
    if (file = e.target.files?[0])?
      console.log file
    
  getFileList = ->
    meteorApply
      method: "spaces.getFileList"
    .then console.log

  <div className="m-1 p-2">
    {<FileSelector/> if showFileSelector}
    {<div className="border border-red-500">
      <input id="file-input" type="file" onChange={onFileInputChange}/>
      <button onClick={send}>send</button>
    </div> if showUpload}
    <div>
      <button onClick={toggleFileSelector}>add Link</button>
      <button onClick={toggleFileSelector}>add Image</button>
      <button onClick={toggleShowUpload}>toggle upload</button>
      <button onClick={getFileList}>log filelist</button>
    </div>
  </div>