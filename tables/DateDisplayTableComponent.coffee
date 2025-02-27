import React from 'react'
import {DateTime} from 'luxon'

#TODO get locale from same mechanism as primereact
dateTimeDefaultParams =
  locale: 'de',
  zone: 'gmt',
  format: 'dd.MM.yyyy HH:mm:ss'

export DateDisplayTableComponentWithNullString = (nullString) -> ({row, columnKey, schemaBridge, onChangeField, mayEdit}) ->
  fieldSchema = schemaBridge._schema.properties[columnKey]

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
        nullString
    }
  </span>

export DateDisplayTableComponent = DateDisplayTableComponentWithNullString ''
