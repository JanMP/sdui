import React from 'react'
import {Card} from 'primereact/card'

export DefaultMetaDataDisplay = ({metaData, linkedItems}) ->

  return null unless metaData?.length

  onClickFor = (item) ->
    ->
      console.log item.data
      window.open item.data.url, '_blank'

  <div className="overflow-x-scroll">
    <div className="w-1rem h-8rem flex gap-2">
      {
        metaData
        .filter (item) -> (not linkedItems?) or linkedItems.has item._id
        .sort((a,b) -> b.createdAt - a.createdAt)
        .map (item) ->
          <div key={item.data._id} className="w-12rem relative flex-shrink-0 " onClick={onClickFor item}>
            <img width="100%" src={item.data.image} />
            <div className="absolute top-0 left-0 w-full text-xl text-white text-0 bg-black-alpha-30">
              {item.data.title}
            </div>
          </div>
      }
    </div>
  </div>
