import React from 'react'
import {connectField, filterDOMProps} from 'uniforms'


export default connectFieldWithLabel = (Component) ->

  ComponentWithLabel = ({props...}) ->
    <div {(filterDOMProps props)...}>
      {<label htmlFor={props.id}>{props.label}</label> if props.label?}
      <Component {props...}/>
    </div>

  connectField ComponentWithLabel, kind: 'leaf'
