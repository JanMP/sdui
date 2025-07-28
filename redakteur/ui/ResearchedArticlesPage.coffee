import React, {useEffect} from 'react'
import {SdList} from 'meteor/janmp:sdui'


ListItemContent = ({rowData, measure}) ->

  useEffect ->
    measure()
    undefined
  , [rowData]

  openInNewWindow = (url) -> (e) ->
    e.preventDefault()
    e.preventDefault()
    window.open url, '_blank', 'width=800,height=600'


  <div className="w-full border-bottom-2 border-300 p-2">
    <div className="flex flex-row">
      <div className="text-4xl mr-2"> {if rowData.usable then '✅' else '❌'} </div>
      <div>
        <div>
          <span className="text-sm text-600 mr-2">{rowData.feedMetaData?.title ? 'n/a'}</span>
          <span className="text-sm text-600">{rowData.pubDate?.toLocaleString('de-DE') ? 'n/a'}</span>
        </div>
        <a className="text-xl" href={rowData.link} target="_blank" rel="noopener noreferrer" onClick={openInNewWindow rowData.link}>{rowData.title}</a>
      </div>
      </div>
    <div className="mt-1" dangerouslySetInnerHTML={{__html: rowData.contentSnippet}} />
    {
      if rowData.similarArticles?.length
        <div>
          {
            rowData.similarArticles
            .filter (article) -> article.score isnt 1
            .map (article) ->
              <div className="mt-3 px-4" key={article._id}>
                <div className="">{(article.score * 100).toFixed 1}%</div>
                <div>
                  {
                    if article.feedMetaData?.title?
                      <span className="text-sm text-600 mr-2">{article.feedMetaData.title}</span>
                  }
                  <span className="text-sm text-600">{article.pubDate?.toLocaleString('de-DE')}</span>
                </div>
                <a className="text-lg" href={article.link} target="_blank" rel="noopener noreferrer" onClick={openInNewWindow article.link}>{article.title}</a>
                <div className="mt-1" dangerouslySetInnerHTML={{__html: article.contentSnippet}} />
              </div>
          }
        </div>
    }
  </div>


export createResearchedArticlesPage = ({dataOptions}) -> ->
  <SdList
    dataOptions={dataOptions}
    customComponents={{ListItemContent}}
  />