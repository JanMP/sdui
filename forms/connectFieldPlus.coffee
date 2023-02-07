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

    outerClassName = "u-form-field"
    if fieldClassName?
      outerClassName += ' | ' + fieldClassName
    
    if props.tooltip?
      props.tooltipOptions ?=
        position: 'top'
        showDelay: 500

    if props.fieldType is Boolean
      labelPosition ?= 'right'
    labelPosition ?=
      if props.fieldType is Boolean
        'right'
      else
        'top'

    if error?
      props.className += " p-invalid"

    props.locale ?= 'de'

    useEffect ->
      console.log props
    , [props]
   
    <div className={outerClassName}>
      {
        unless label?
          <Component {props...}/>
        else
          switch labelPosition
            when 'floating'
              <span className="p-float-label">
                <Component {props...}/>
                <label htmlFor={props.id}>{t label}</label>
              </span>
            when 'left'
              <div className="inline-left">
                <label htmlFor={props.id}>{t label}</label>
                <Component {props...}/>
              </div>
            when 'right'
              <div className="inline-right">
                <Component {props...}/>
                <label htmlFor={props.id}>{t label}</label>
              </div>
            else
              <div className="inline-top">
                <label htmlFor={props.id}>{t label}</label>
                <Component {props...}/>
              </div>
      }
    </div>


  connectField WrappedComponent, kind: 'leaf'