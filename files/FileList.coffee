import React from 'react'
import {SdList} from '../tables/SdList.coffee'
import {DefaultHeader} from '../tables/DefaultHeader.coffee'
import toStringWithUnitPrefix from '../common/toStringWithUnitPrefix.coffee'
import {FileUploadButton} from './FileUploadButton.coffee'
import {FontAwesomeIcon} from '@fortAwesome/react-fontawesome'
import {faUser} from '@fortawesome/free-solid-svg-icons/faUser'
import {faTriangleExclamation} from '@fortawesome/free-solid-svg-icons/faTriangleExclamation'

ListItemContent  = ({rowData}) ->
  <div className="flex p-2 gap-4 overflow-hidden">
    <div>
      {
        if rowData.thumbnailUrl and rowData.status is 'ok'
          <div className="h-[100px] w-[150px] flex justify-center">
            <img className="shadow" src={rowData.thumbnailUrl} alt={rowData.name} />
          </div>
        else
          <div className="h-[100px] w-[150px] bg-secondary-300 flex justify-center items-center">
            <div className="text-white text-3xl">?</div>
          </div>
      }
    </div>
    <div>
      <a href={rowData.url}>
        <span className="whitespace-nowrap text-ellipsis" title={rowData.name}>{rowData.name}</span>
      </a>
       {<div className="text-sm italic text-secondary-600">{rowData.label}</div> if rowData.label?}
      <div className="text-sm">{<FontAwesomeIcon icon={faUser}/> unless rowData.isCommon} {rowData.type} {toStringWithUnitPrefix rowData.size, onlyFromE3: true}B</div>
      {<div className="text-danger-500">
        <FontAwesomeIcon className="mr-2" icon={faTriangleExclamation}/>
        <span>{rowData.status}</span>
      </div> unless rowData.status is 'ok'}
    </div>
  </div>

export FileList = ({dataOptions}) ->
  {tableDataOptions} = dataOptions

  Header = (props) ->
    DefaultHeader {{
      props...
      AdditionalButtonsRight: -> <FileUploadButton dataOptions={dataOptions}/>
    }...}

  <>
    <SdList
      dataOptions={tableDataOptions}
      customComponents={{ListItemContent, Header}}
    />
  </>