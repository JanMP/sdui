import React from 'react'

export FormattedJSON = ({data}) ->
  preStyle =
    whiteSpace: 'pre-wrap'
    wordWrap: 'break-word'

  <pre style={preStyle}>
    {JSON.stringify(data, null, 2)}
  </pre>
