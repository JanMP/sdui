import React, {useEffect} from 'react'
import {SdTable, ActionButton} from 'meteor/janmp:sdui'
import {Button} from 'primereact/button'
import {Jobs} from 'meteor/msavin:sjobs'

customComponents =
  rightButtonColumnWidth: 180
  AdditionalButtonsRight: ({rowData}) ->
    <div className="mr-5">
      <ActionButton
        method="jobs.stop"
        data={rowData}
        className="p-button-icon-only p-button-text"
        icon="pi pi-fw pi-pause"
      />
      <ActionButton
        method="jobs.execute"
        data={rowData}
        className="p-button-icon-only p-button-text"
        icon="pi pi-fw pi-play"
      />
      <ActionButton
        method="jobs.remove"
        data={rowData}
        className="p-button-icon-only p-button-text"
        icon="pi pi-fw pi-trash"
      />
    </div>

export SdJobsTable = ({dataOptions}) ->

  <SdTable dataOptions={dataOptions}/>