import React from 'react'
import classnames from 'classnames'
import { HTMLFieldProps, connectField, filterDOMProps } from 'uniforms'
import {MarkdownEditor} from '../markdown/MarkdownEditor.coffee'
import 'ace-builds/src-noconflict/ext-searchbox'
import 'ace-builds/src-noconflict/mode-markdown'
import 'ace-builds/src-noconflict/theme-chrome'
import { useMeasure } from "react-use"



MarkdownField = connectField ({
  onChange,
  value,
  label,
  disabled,
  error,
  required,
  errorMessage,
  className,
  showInlineError,
  id,
  props...
}) ->

  [ref, {width}] = useMeasure()

  
  <div
    className={classnames(className, { disabled, error, required, value }, 'field')} {...filterDOMProps(props)}
    ref={ref}
  >
    {### <pre>{JSON.stringify(value, null, 2)}</pre> ###}
    {<label htmlFor={id}>{label}</label> if label?}
    <MarkdownEditor
      value={value}
      onChange={onChange}
      editorWidth={width}
      editorHeight={400}
    />

    {
      if (error and showInlineError)
        <div className="ui red basic pointing label">{errorMessage}</div>
    }
  </div>

export default MarkdownField