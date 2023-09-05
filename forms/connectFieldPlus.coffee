import React, {useEffect} from 'react'
import {connectField, filterDOMProps} from 'uniforms'
import {useTranslation} from 'react-i18next'


export default (Component) ->

  WrappedComponent = ({
    label, labelPosition
    error
    fieldClassName
    props...
  }) ->

    {t} = useTranslation()

    outerClassName = "flex flex-column my-4"
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

    # useEffect ->
    #   console.log props
    # , [props]
   
    <div className={outerClassName}>
      {
        unless label?
          <Component {props...}/>
        else
          switch labelPosition
            when 'floating'
              <span className="p-float-label">
                <Component {props...}/>
                <label htmlFor={props.id}>{translatedLabel}</label>
              </span>
            when 'left'
              <div className="flex align-items-center gap-2">
                <label className="text-right w-10rem" htmlFor={props.id}>{translatedLabel}</label>
                <Component {props...}/>
              </div>
            when 'right'
              <div className="flex align-items-center gap-2">
                <Component {props...}/>
                <label htmlFor={props.id}>{translatedLabel}</label>
              </div>
            else
              <div className="flex flex-column">
                <label htmlFor={props.id}>{translatedLabel}</label>
                <Component {props...}/>
              </div>
      }
    </div>


  connectField WrappedComponent, kind: 'leaf'