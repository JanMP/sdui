import React from 'react'
import {DynamicTableField} from './DynamicTableField'
import _ from 'lodash'

export AutoTableAutoField = ({row, columnKey, schemaBridge, onChangeField, measure, mayEdit}) ->
  fieldSchema = schemaBridge.schema._schema[columnKey]
  inner =
    if (component = fieldSchema.sdTable?.component)?
      try
        component {row, columnKey, schemaBridge, onChangeField, measure, mayEdit}
      catch error
        console.error error
        console.log 'the previous error happened in AutotableAutoField with params', {row, columnKey, schemaBridge, component}
    else if fieldSchema.sdTable?.editable and not row._disableEditForRow
      <DynamicTableField {{row, columnKey, schemaBridge, onChangeField, mayEdit}...}/>
    else if fieldSchema.sdTable?.markup
      <div dangerouslySetInnerHTML={__html: row[columnKey]} />
    else
      switch fieldType = fieldSchema.type.definitions[0].type
        when Date
          <span>{row[columnKey]?.toLocaleString()}</span>
        when Boolean
          if row[columnKey] then <i className="pi pi-check"/> else <i className="pi pi-times"/>
        when Array
          row[columnKey]?.map (entry, i) ->
            if _.isObject entry
              <pre>{JSON.stringify row[columnKey][i]}</pre>
            else
              <div key={i} style={whiteSpace: 'normal', marginBottom: '.2rem'}>{entry}</div>
        else
          if _.isObject row[columnKey] or _.isArray row[columnKey]
            <pre>{JSON.stringify row[columnKey], null, 2}</pre>
          else
            <div style={whiteSpace: 'normal'}>{row[columnKey]}</div>

  <div className="py-2">{inner}</div>