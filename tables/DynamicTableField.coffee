import React from 'react'
import DynamicField from '/forms/DynamicField.coffee'

###*
  @type {(row: object, columnKey: string, schemaBridge: any, onChangeField: function, mayEdit: boolean) =>}
  ###
export default DynamicTableField = ({row, columnKey, schemaBridge, onChangeField, mayEdit}) ->

  onChange = (d) ->
    onChangeField
      _id: row?._id ? row?.id
      changeData: "#{columnKey}": d

  <DynamicField
    key={"#{row?._id}#{columnKey}"}
    schemaBridge={schemaBridge}
    fieldName={columnKey}
    label={false}
    value={row[columnKey]}
    onChange={onChange}
    validate="onChange"
    mayEdit={mayEdit}
  />
