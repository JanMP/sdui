import React, {useEffect} from 'react'

export SessionListItemContent = ({rowData}) ->

  usernames =
    rowData?.users
    ?.map (user) ->
      user?.username
    ?.join ', '

  useEffect ->
  , [rowData]

  <div className="flex-grow-1 p-2">
    <div className="text-xs font-light text-400">{rowData?.createdAt?.toLocaleDateString()}, {rowData?.createdAt?.toLocaleTimeString()}</div>
    <div className="text-lg">{rowData?.title}</div>
    <div className="text-xs font-light text-300">{rowData?.model}</div>
  </div>