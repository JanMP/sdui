import React, {useEffect, useState} from 'react'
import {SdList} from 'meteor/janmp:sdui'


ListItemContent = ({rowData, measure}) ->

  useEffect ->
    measure()
    undefined
  , [rowData]

  <div className="w-full border-bottom-2 border-300 p-2 cursor-pointer">
    Prompt für Artikel Typ: {rowData?.promptType ? 'fnord'}
    {
      if rowData?.text
        # 2 rows with ellipsis
        <div className="mt-2 text-sm text-600" style={{overflow: 'hidden', display: '-webkit-box', WebkitBoxOrient: 'vertical', WebkitLineClamp: 2}}>
          {rowData.text}
        </div>
      else
        <div className="mt-2 text-sm text-600">Kein Prompt definiert</div>
    }
  </div>

export createPromptsPage = ({dataOptions}) -> ->
  <SdList
    dataOptions={dataOptions}
    customComponents={{ListItemContent}}
  />