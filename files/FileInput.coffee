import React, {useState} from 'react'
import setClassNamesForProps from '../forms/uniforms-custom/src/setClassNamesForProps'
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms';
import fetchProgress from 'fetch-progress'


generatePreview = ({file}) ->
  reader = new FileReader()
  new Promise (resolve, reject) ->
    reader.onload = (e) -> resolve e.target?.result
    reader.readAsDataURL file


generateThumbnail = ({file, maxW, maxH}) ->
  reader = new FileReader()
  canvas = document.createElement 'canvas'
  ctx = canvas.getContext '2d'

  new Promise (resolve, reject) ->
    reader.onload = (e) ->
      img = new Image()
      img.onload = ->
        scaleRatio = (Math.min maxW, maxH) / (Math.max img.width, img.height)
        canvas.width = w = img.width * scaleRatio
        canvas.height = h = img.height * scaleRatio
        ctx.clearRect 0, 0, w, h
        ctx.drawImage img, 0, 0, w, h
        canvas.toBlob (blob) ->
          unless blob?
            reject 'could not create blob'
          resolve new File [blob], file.name + '.thumbnail.png', type: 'image/png'
      img.onerror = -> reject 'no-thumbnail'
      img.src = e.target.result
    reader.readAsDataURL file


export FileInput = ({
autoComplete,
disabled,
id,
inputRef,
label,
name,
onChange,
placeholder,
readOnly,
value,
props...}) ->

  [preview, setPreview] = useState null


  handleChange = (e) ->
    files = [e.target.files...]
    file = files[0]
    generatePreview {file}
      .then setPreview
      .catch console.error
    generateThumbnail {file, maxW: 150, maxH: 100}
      .then (thumbnail) ->
        onChange {file, thumbnail}
      .catch ->
        onChange {file, thumbnail: null}

  onError = (e) -> setPreview null

  <div className={setClassNamesForProps props}>

    {
      if preview?
        <div className="h-[300px] mx-auto p-4">
          <img
            className="max-w-auto h-full mx-auto"
            src={preview} alt="preview" onError={onError}
          />
        </div>
    }
    {<label htmlFor={id}>{label}</label> if label? and not props.hasFloatingLabel}
    <div className="w-full">
        <input
          type="file"
          disabled={disabled}
          id={id}
          name={name}
          onChange={handleChange}
          placeholder={placeholder}
          readOnly={readOnly}
          ref={inputRef}
        
        />
    </div>
    {<label htmlFor={id}>{label}</label> if label? and props.hasFloatingLabel}
  </div>


export FileInputField = connectField FileInput, kind: 'leaf'