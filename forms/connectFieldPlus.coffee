import React, {useEffect} from 'react'
import {connectField, filterDOMProps} from 'uniforms'
import {useTranslation} from 'react-i18next'


export default connectFieldPlus = (Component) ->

  WrappedComponent = ({
    label, labelPosition
    required
    error
    fieldClassName
    props...
  }) ->

    {t} = useTranslation()

    outerClassName = "flex flex-column#{if label then ' pt-3' else ''}"
    if fieldClassName?
      outerClassName += ' | ' + fieldClassName

    if props.tooltip?
      props.tooltipOptions ?=
        position: 'top'
        showDelay: 500

    labelPosition ?=
      if props.fieldType is Boolean
        'right'
      else
        'top'

    if error?
      props.className += " p-invalid"

    translatedLabel =
      unless label is ""
        t props?.name , label
      else ""

    labelSpan =
      if required
        <span className="text-red-500">*</span>
      else null

    <div className={outerClassName}>
      {
        unless label?
          <Component {props...}/>
        else
          switch labelPosition
            when 'floating'
              <span className="p-float-label">
                <Component {props...}/>
                <label htmlFor={props.id}>{translatedLabel}{labelSpan}</label>
              </span>
            when 'left'
              <div className="flex align-items-center gap-2">
                <label className="text-right w-10rem" htmlFor={props.id}>{translatedLabel}{labelSpan}</label>
                <Component {props...}/>
              </div>
            when 'right'
              <div className="flex align-items-center gap-2">
                <Component {props...}/>
                <label htmlFor={props.id}>{translatedLabel}{labelSpan}</label>
              </div>
            else
              <div className="flex flex-column">
                <label htmlFor={props.id}>{translatedLabel}{labelSpan}</label>
                <Component {props...}/>
              </div>
      }
      {
        if error and props.showInlineError
          <div className="p-error">{error?.message}</div>
      }
    </div>


  connectField WrappedComponent, kind: 'leaf'