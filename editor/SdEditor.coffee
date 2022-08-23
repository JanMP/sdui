import React, {useEffect, useRef} from 'react'
import AceEditor from 'react-ace'
import 'ace-builds/src-noconflict/ext-searchbox'
import 'ace-builds/src-noconflict/mode-markdown'
import 'ace-builds/src-noconflict/theme-chrome'

import {useConfig} from '../config/config.coffee'
# import {FileSelect} from '../files/FileSelect.coffee'
import useSize from '@react-hook/size'

DefaultHeader = ({instance}) ->
  editor = instance?.current?.editor

  {files} = useConfig()

  return null unless files?

  <div className="p-1 border-b border-secondary-500 | editor-header__container">
    No Files UI for now, sorry.
    {###
    <FileSelect dataOptions={files} editor={editor}/>
    ###}
  </div>


###*
  @type {({value, onChange, editorWidth, editorHeight, mode, theme, Header} : {value: string, onChange: (newValue: string) => void, editorWidth?: string, editorHeight?: string, mode?: string, theme?: string, Header?: React.FC})  => React.FC}
  ###
export SdEditor = ({value = '', onChange, editorWidth = "100%", editorHeight = "100%", mode, theme, Header}) ->

  mode ?= "markdown"
  theme ?= "chrome"

  Header ?= DefaultHeader

  instance = useRef null
  editor = instance?.current?.editor

  container = useRef null
  size = useSize container

  useEffect ->
    editor?.resize()
  , [size]

  <div className="w-full h-full | editor_container" ref={container}>
    <Header instance={instance}/>
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
  </div>