import React, {useEffect} from 'react'
import {connectField, filterDOMProps} from 'uniforms'


export default (Component) ->

  WrappedComponent = ({label, hasFloatingLabel, error, fieldClassName, props...}) ->

    className = "u-form-field"
    if fieldClassName?
      className += ' | ' + fieldClassName
    
    useEffect ->
      console.log error
    , [error]

    if error?
      props.className += " p-invalid"

   
    <div className={className}>
      {
        switch
          when label? and hasFloatingLabel
            <span className="p-float-label">
              <Component {props...}/>
              <label htmlFor={props.id}>{label}</label>
            </span>
          when label?
            <>
              <label htmlFor={props.id}>{label}</label>
              <Component {props...}/>
            </>
          else
            <Component {props...}/>
      }
    </div>


  connectField WrappedComponent, kind: 'leaf'