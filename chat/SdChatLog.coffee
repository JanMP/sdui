import React, {useState, useEffect, useRef} from 'react'
import {SdTable, meteorApply, MarkdownDisplay, FormattedJSON, useToast} from 'meteor/janmp:sdui'
import {Dialog} from 'primereact/dialog'
import {Checkbox} from 'primereact/checkbox'
import _ from 'lodash'


HistoryDisplay = ({sourceName, rowData}) ->

  [messages, setMessages] = useState null
  [showRaw, setShowRaw] = useState false

  toast = useToast()

  useEffect ->
    if rowData?._id?
      meteorApply
        method: "#{sourceName}.getMessagesForSession"
        data: sessionId: rowData._id
      .then setMessages
      .catch (error) ->
        toast.show
          severity: 'error'
          summary: 'Fehler'
          detail: error.message
    undefined
  , [rowData]


  <div className="p-3">
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
            {_.compact [
              if entry?.text?.length
                <MarkdownDisplay
                  markdown={entry?.text}
                  contentClass="surface-100 px-3 py-1 | chat-message"
                />
              if isFunctionCall = entry?.tools?.length > 0
                entry.tools.map (tool, index) ->
                  <div className="text-blue-200 p-3">
                    <span>Funktion: </span>
                    <span className="font-bold">{tool.name} </span>
                    <span>mit Argumenten: </span>
                    <FormattedJSON data={tool.args} />
                  </div>
              if isFunctionResult = entry?.chatRole is 'function' and entry?.result?.length > 0
                <div className="text-blue-100 p-3">
                 {entry?.results}
                </div>
              if entry?.error?
                <div className="text-red-200 px-3 py-1">
                  <span className="font-bold">Fehler: </span>
                  <FormattedJSON data={entry?.error} />
                </div>
              # else unless entry?.text?.length or isFunctionResult or entry?.error?
              if showRaw
                <div className="surface-200 px-3 py-1 text-sm">
                  <FormattedJSON data={entry} />
                </div>
            ]
            }
          </div>
        </div>
    }
    <div className="flex justify-content-end">
      <div className="mt-2 flex align-items-center">
        <Checkbox
          inputId="raw"
          onChange={(e) -> setShowRaw e.checked}
          checked={showRaw}
        />
        <label htmlFor="raw" className="ml-2">Rohdaten anzeigen</label>
      </div>
    </div>
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