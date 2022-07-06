import React, {useRef} from 'react'
import AceEditor from 'react-ace'
import 'ace-builds/src-noconflict/ext-searchbox'
import 'ace-builds/src-noconflict/mode-markdown'
import 'ace-builds/src-noconflict/theme-chrome'

###*
  @type {({value, onChange, editorWidth, editorHeight, instance} : {value: string, onChange: (newValue: string) => void, editorWidth?: string, editorHeight?: string, instance: any})  => React.FC}
  ###
export MarkdownEditor = ({value = '', onChange, editorWidth = "100%", editorHeight = "100%", instance}) ->

  <AceEditor
    ref={instance}
    mode="markdown"
    theme="chrome"
    width={editorWidth}
    height={editorHeight}
    value={value}
    onChange={onChange}
    setOptions={
      wrap: true,
      showInvisibles: true
    }
  />