import React, {useState, useEffect, useRef} from 'react'
import {SdTable, meteorApply, MarkdownDisplay} from 'meteor/janmp:sdui'

import {Dialog} from 'primereact/dialog'
import {Toast} from 'primereact/toast'


HistoryDisplay = ({sourceName, rowData}) ->

  [messages, setMessages] = useState null
  toast = useRef null

  useEffect ->
    if rowData?._id?
      meteorApply
        method: "#{sourceName}.getMessagesForSession"
        data: sessionId: rowData._id
      .then setMessages
      .catch (error) ->
        toast.current?.show
          severity: 'error'
          summary: 'Fehler'
          detail: error.message
    undefined
  , [rowData]


  <div className="p-3">
    <Toast ref={toast} />
    {
      messages?.map (entry, index) ->
        <div className="mt-2" key={index}>
          <div>
            <span className="font-bold">{entry?.chatRole}</span>
            <span className="font-sm"> {entry?.createdAt.toLocaleString 'de-DE'}</span>
            <span className="font-bold"> ${entry?.costInUSD}:</span>
          </div>
          {
            if entry.feedback?
              <div className="flex align-items-center surface-200 ml-2">
                {
                  if entry?.feedback?.thumbs is 'down'
                    <div><i className="pi pi-thumbs-down p-3" style={color: 'red', fontSize: '2rem'}/></div>
                  else if entry?.feedback?.thumbs is 'up'
                    <div><i className="pi pi-thumbs-up p-3" style={color: 'green', fontSize: '2rem'}/></div>
                  else
                    <div><i className="pi pi-thumbs-up p-3" style={color: 'grey', fontSize: '2rem'}/></div>
                }
                <div className="ml-2">
                  <MarkdownDisplay markdown={entry?.feedback?.comment}/>
                </div>
              </div>
          }
          <div className="ml-2">
            {
              if entry?.text?.length
                <MarkdownDisplay
                  markdown={entry?.text}
                  contentClass="surface-100 px-3 py-1"
                />
              else if entry?.functionCall?
                <div className="bg-blue-100 p-3">
                  <span>Funktion: </span>
                  <span className="font-bold">{entry?.functionCall.name} </span>
                  <span>mit Argumenten: </span>
                  <pre className="font-bold">{JSON.stringify entry?.functionCall.arguments, null, 2}</pre>
                </div>
              else if entry?.error?
                <div className="bg-red-100 px-3 py-1">
                  <span className="font-bold">Fehler: </span>
                  <pre>{JSON.stringify entry?.error, null, 2}</pre>
                </div>
              else
                <div className="surface-200 px-3 py-1">
                  <span className="font-bold">Keine Nachricht</span>
                </div>
            }
          </div>
        </div>
    }
  </div>


export SdChatLog = ({dataOptions}) ->
  [selectedRowData, setSelectedRowData] = useState null
  [historyDisplayIsOpen, setHistoryDisplayIsOpen] = useState false

  onRowClick = ({rowData}) ->
    setSelectedRowData rowData
    setHistoryDisplayIsOpen true

  onHide = ->
    setHistoryDisplayIsOpen false
    setSelectedRowData null


  <>
    <Dialog
      style={maxWidth: '60rem'}
      visible={historyDisplayIsOpen}
      onHide={onHide}
      header="Verlauf für Session"
      dismissableMask={true}
    >
      <HistoryDisplay sourceName={dataOptions.sourceName} rowData={selectedRowData}/>
    </Dialog>
    <SdTable
      dataOptions={{dataOptions..., onRowClick}}
    />
  </>