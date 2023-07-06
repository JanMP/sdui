import React, {useEffect} from 'react'

export SessionListItemContent = ({rowData}) ->

  usernames =
    rowData?.users
    ?.map (user) ->
      user?.username
    ?.join ', '

  useEffect ->
    console.log rowData, usernames
  , [rowData]

  <div className="flex-grow-1 p-2">
    <div className="text-lg">{rowData?.title}</div>
    <div className="text-sm font-light">{usernames}</div>
  </div>