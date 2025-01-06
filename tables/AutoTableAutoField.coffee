import React from 'react'
import {DynamicTableField} from './DynamicTableField'
import {DateTime} from 'luxon'
import _ from 'lodash'

#TODO get locale from same mechanism as primereact
dateTimeDefaultParams =
  locale: 'de',
  zone: 'gmt',
  format: 'dd.MM.yyyy HH:mm:ss'

export AutoTableAutoField = ({row, columnKey, schemaBridge, onChangeField, measure, mayEdit}) ->
  fieldSchema = schemaBridge._schema.properties[columnKey]
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
      switch fieldSchema.type
        when 'object'
          if _.isDate row[columnKey]
            <span>
              {
                if row[columnKey]?
                  params = {dateTimeDefaultParams..., (fieldSchema.sdTable ?  {})...}
                  DateTime
                    .fromJSDate row[columnKey]
                    ?.setLocale params.locale
                    ?.setZone params.zone
                    ?.toFormat params.format
                else
                  ''
              }
            </span>
          else
            <pre>{JSON.stringify row[columnKey], null, 2}</pre>
        when 'boolean'
          if row[columnKey] then <i className="pi pi-check"/> else <i className="pi pi-times"/>
        when 'array'
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