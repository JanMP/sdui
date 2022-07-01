import React, {useState} from 'react'
import AsyncSelect from 'react-select/async'
import {components} from 'react-select'
import {meteorApply, currentUserIsInRole} from 'meteor/janmp:sdui'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faUser} from '@fortAwesome/free-solid-svg-icons/faUser'
import {faTriangleExclamation} from '@fortAwesome/free-solid-svg-icons/faTriangleExclamation'
import {faClipboardQuestion} from '@fortAwesome/free-solid-svg-icons/faClipboardQuestion'
import {faImage} from '@fortAwesome/free-solid-svg-icons/faImage'
import {faLink} from '@fortAwesome/free-solid-svg-icons/faLink'
import toStringWithUnitPrefix from '../common/toStringWithUnitPrefix.coffee'


export FileSelect = ({dataOptions, menuPlacement}) ->
  {sourceName} = dataOptions.tableDataOptions

  [option, setOption] = useState null
  isImage = option?.value?.type?.startsWith?('image')

  promiseOptions = (search) ->
    meteorApply
      method: "#{sourceName}.getRows"
      data:
        search: search
        limit: 100
        query: {}
        skip: 0
        sort: key: 1
    .then (result) ->
      console.log result
      result.map (file) ->
        key: file._id
        value: file
        label: file.label
        isCommon: file.isCommon
        status: file.status

  copy = ->
    return unless (value = option?.value)?
    text = "#{if isImage then '!' else ''}[#{value.label ? ''}](#{value.url})"
    navigator.clipboard.writeText text

  Option = (props) ->
    {value} = props
    <components.Option {props...}>
      <div className="flex gap-4">
        {
          if value.thumbnailUrl? and value.status is 'ok'
            <div className="flex-none w-[100px] h-[65px] flex justify-center">
              <img className="shadow" src={value.thumbnailUrl} alt={value.name} />
            </div>
          else
            <div className="flex-none w-[100px] h-[65px] bg-secondary-300 flex justify-center items-center">
              <div className="text-white text-3xl">?</div>
            </div>
        }
        <div>
          <div className="overflow-hidden whitespace-nowrap text-ellipsis" title={value.name}>{value.name}</div>
          {<div className="text-sm italic text-secondary-600">{value.label}</div> if value.label?}
          <div className="text-sm">
            {<FontAwesomeIcon className="text-danger-500 mr-2" icon={faTriangleExclamation}/> unless value.status is 'ok'}
            {<FontAwesomeIcon className="mr-2" icon={faUser}/> unless value.isCommon}
            <span>{value.type} {toStringWithUnitPrefix value.size, onlyFromE3: true}B</span>
          </div>
        </div>
      </div>
    </components.Option>

  IndicatorsContainer = ->
    
    unless option?.value?
      return <FontAwesomeIcon className="mr-2 text-secondary-300" icon={faClipboardQuestion}/>

    icon = if isImage then faImage else faLink
    
    <button
      className="button primary"
      onClick={copy}
      onMouseDown={(e) -> e.stopPropagation()}
    >
      <FontAwesomeIcon icon={icon}/>
      <span className="ml-2">copy</span>
    </button>


  <AsyncSelect
    className="text-left z-50"
    loadOptions={promiseOptions}
    onChange={setOption}
    components={{IndicatorsContainer, Option}}
    cacheOptions defaultOptions
    menuPlacement={menuPlacement}
  />