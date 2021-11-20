import React from 'react'
import AceEditor from 'react-ace'
import 'ace-builds/src-noconflict/ext-searchbox'
import 'ace-builds/src-noconflict/mode-markdown'
import 'ace-builds/src-noconflict/theme-chrome'

const MarkDownEditor = ({value, onChange, editorWidth, editorHeight} : {value: string, onChange: (newValue: string) => void, editorWidth: number, editorHeight: number})  => {
 return(
        <AceEditor mode="markdown" theme="chrome" width={editorWidth} height={editorHeight} value={value} onChange={onChange} setOptions={{
        wrap: true,
        showInvisibles: true
      }} />
  
  ) };

  export default MarkDownEditor