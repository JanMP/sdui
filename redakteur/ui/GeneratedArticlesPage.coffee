import React, {useEffect, useState} from 'react'
import {ActionButton, SdList, meteorApply,
useToast, MarkdownDisplay, FormattedJSON,
ManagedForm} from 'meteor/janmp:sdui'
import {useNavigate, useParams} from 'react-router-dom'
import {Dialog} from 'primereact/dialog'
import {Button} from 'primereact/button'
import _ from 'lodash'

export createGeneratedArticlesPage = ({
sourceName
dataOptions
createionParamsSchema
}) ->

  PromptDisplay = ->
    [model, setModel] = useState {}
    toast = useToast()

    onSubmit = (data) ->
      meteorApply
        method: "#{sourceName}.generatedArticles.create"
        data: data
      .then ->
        toast.show
          severity: 'success'
          summary: 'Success'
          detail: 'Artikel wird erstellt'
      .catch (error) ->
        toast.show
          severity: 'error'
          summary: 'Fehler'
          detail: error.message

    <ManagedForm
      schemaBridge={creationParamsSchema.bridge}
      onChangeModel={setModel}
      onSubmit={onSubmit}
      model={{}}
    />

  PublishButton = ({article, onReload}) ->
    <ActionButton
      method='macredakteur.generatedArticles.publish'
      data={id: article?._id}
      label='Publish'
      icon='pi pi-send'
      className='p-button-outlined mr-4 flex-shrink-0'
      onSuccess={onReload}
      confirmation='Artikel wirklich an Drupal senden?'
      disabled={article?.published}
    />

  ArticleDisplay = ({article}) ->
    jsonData = article.rawOutput

    quickReadMarkdown = """
      <div class="text-lg surface-100 p-1 mb-3 border-round">
        <ul>
          <li>#{jsonData?.quickread?.punkt1}</li>
          <li>#{jsonData?.quickread?.punkt2}</li>
          <li>#{jsonData?.quickread?.punkt3}</li>
        </ul>
      </div>
    """

    explainedMarkdown = """
      <div class="surface-100 py-3 px-4 mb-3 border-round">
        <div class="text-lg">#{jsonData?.explained?.begriff}</div>
        <div class="text-base p-2 pl-4">#{jsonData?.explained?.erklaerung}</div>
      </div>
    """

    markdown = """
      # #{article?.title}

      #{article?.content}
    """
    .replace '[QUICKREAD]', quickReadMarkdown
    .replace '[EXPLAINED]', explainedMarkdown

    <div>
      <div className="p-4 surface-200 text-lg border-round">{article?.teaser ? '[kein Teaser]'}</div>
      <MarkdownDisplay markdown={markdown}/>
      <div className="mt-1">
        <h2>Quellen (vom Agenten gewählt):</h2>
        {
          if jsonData?.links?.map?
            jsonData?.links?.map ({url, text}) ->
              <div className="text-lg text-600" key={url}>
                <a href={url} target=".blank" rel="noopener noreferrer" className="mr-1">{text}</a>
              </div>
          else
            <div className="text-lg text-600">[keine Quellen]</div>
        }
      </div>
      <div classname="mt-1">
        <h2>Context</h2>
        <div className="text-xs surface-100 px-4 py-1 w-full" style={{whiteSpace: 'pre-wrap', wordBreak: 'break-word'}}>
          {article.context}
        </div>
      </div>
      <div className="mt-4">
        <h2>JSON-Output:</h2>
        <div className="text-xs surface-100 px-4 py-1">
          <FormattedJSON data={jsonData ? {}}/>
        </div>
      </div>
    </div>


  ListItemContent = ({rowData, measure}) ->
    useEffect ->
      measure()
      undefined
    , [rowData]

    <div className="w-full border-bottom-2 border-300 p-2 cursor-pointer">
      <div>
        <span className="text-sm text-400">{rowData.createdAt?.toLocaleString('de-DE')}</span>
        {
          if rowData.published
            <span className="text-sm text-green-500 ml-2">published</span>
        }
      </div>
      <div className="text-xl text-primary">{rowData.title}</div>
      <div className="text-base text-600">{rowData.teaser ? '[kein Teaser]'}</div>
    </div>


  createGeneratedArticlesPage = ->
    navigate = useNavigate()
    params = useParams()
    toast = useToast()
    [article, setArticle] = useState null
    [articleDisplayIsOpen, setArticleDisplayIsOpen] = useState false
    [promptDisplayIsOpen, setPromptDisplayIsOpen] = useState false
    [reloadTrigger, setReloadTrigger] = useState 0

    onRowClick = ({rowData}) ->
      navigate "/macredakteur/produced-articles/#{rowData._id}"

    onAdd = ->
      setPromptDisplayIsOpen true

    onHideArticleDisplay = ->
      setArticleDisplayIsOpen false
      navigate "/#{sourceName}/produced-articles"

    onHidePromptDisplay = ->
      setPromptDisplayIsOpen false

    handleError = (error) ->
      toast.show
        severity: 'error'
        summary: 'Fehler'
        detail: error.message

    useEffect ->
      console.log 'params', params
      if params.articleId
        meteorApply
          method: "#{sourceName}.generatedArticles.getArticleById"
          data: id: params.articleId
        .catch handleError
        .then setArticle
        .then -> setArticleDisplayIsOpen true
      else
        setArticle null
        setArticleDisplayIsOpen false
      undefined
    , [params, reloadTrigger]

    <>
      <Dialog
        visible={promptDisplayIsOpen}
        onHide={onHidePromptDisplay}
        header="Neuen Artikel generieren"
      >
        <PromptDisplay/>
      </Dialog>
      <Dialog
        visible={articleDisplayIsOpen}
        onHide={onHideArticleDisplay}
        header={
          <div className="flex align-items-between mr-4">
            <PublishButton article={article} onReload={-> setReloadTrigger (x) -> x + 1}/>
            <div>
              <div className="text-xl">{article?.title}</div>
              <div className="text-sm text-600">{article?.createdAt?.toLocaleString('de-DE')}</div>
            </div>
          </div>
        }
        dismissableMask={true}
        maximized={true}
        maximizable={true}
      >
        <ArticleDisplay article={article ? {}}/>
      </Dialog>
      <SdList
        dataOptions={{dataOptions..., onRowClick, onAdd}}
        customComponents={{ListItemContent}}
      />
    </>