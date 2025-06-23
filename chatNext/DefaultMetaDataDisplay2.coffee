import React, {useRef} from 'react'
import {Card} from 'primereact/card'
import {MarkdownDisplay} from 'meteor/janmp:sdui'
import {DateTime} from 'luxon'
import {ErrorBoundary} from '../common/ErrorBoundary.coffee'

formatDate = (date) ->
  DateTime.fromJSDate(date).toLocaleString(DateTime.DATETIME_SHORT_WITH_SECONDS)

export DefaultMetaDataDisplay = ({metaData}) ->
  console.log 'metaData', metaData?.sort (a, b) -> b.createdAt - a.createdAt

  scrollAreaRef = useRef null
 
  <div className="absolute top-0 right-0 bottom-0 left-0 overflow-y-auto overflow-x-hidden" ref={scrollAreaRef}>
    {
      metaData
      ?.sort (a, b) -> b.createdAt - a.createdAt
      .map (item) ->
        <ErrorBoundary key={item._id}>
          {
            switch item.metadata.langgraph_node
              when 'reasoner'
                <Card className="w-full mb-1" key={item._id} title="Reasoner" subTitle={formatDate item?.createdAt}>
                  <MarkdownDisplay
                    markdown={item?.data?.content?[0]?.text}
                    contentClass="text-xs"
                  />
                  <div>
                    {
                      item?.data?.tool_calls.map (call, index) ->
                        switch call?.name
                          when 'brightdata_Unlocker'
                            #link to url
                            <a href={call?.args?.url} target="_blank" rel="noopener noreferrer">
                              {call?.args?.url}
                            </a>
                          else
                            <div>
                              <div className="text-xs text-blue-500">{call?.name}:</div>
                              <div className="ml-4 text-xs text-blue-400">{JSON.stringify call.args}</div>
                            </div>
                    }
                  </div>
                </Card>
              when 'tools'
                switch item.data?.name
                  when 'search'
                    content =
                      try
                        JSON.parse item.data.content
                      catch error
                        console.error 'Error parsing JSON', error
                        []
                    markdown =
                      content
                      .map (entry) ->
                        """
                          #### #{(entry?.score * 100).toFixed(2)}% [#{entry?.title}](#{entry?.url})
                          #{entry?.content}
                        """
                      .join '\n\n'
                    <Card className="w-full mb-1 overflow-x-hidden" key={item._id}
                      title="Tavily Search" subTitle={formatDate item?.createdAt}
                    >
                      <MarkdownDisplay markdown={markdown} contentClass="w-full text-xs"/>
                    </Card>
                  when 'finish'
                    <Card className="w-full mb-1 text-center text-blue-500" key={item._id}>
                      {item?.data?.content}
                    </Card>
                  when 'brightdata_Unlocker'
                    <Card className="w-full mb-1 text-center text-blue-500" key={item._id}
                    >
                      Viewing Website...
                    </Card>
              else
                <Card className="w-full mb-1" key={item._id}
                  title ="Unknown Agent Node #{item.metadata._langgraph_node}" subTitle={formatDate item?.createdAt}
                >
                  <pre className="text-xs text-red-500">
                    {JSON.stringify item, null, 2}
                  </pre>

                </Card>
          }
        </ErrorBoundary>
    }
  </div>