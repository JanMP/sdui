import React from 'react'
import markdownIt from 'markdown-it'
import latex from 'markdown-it-latex'

import 'markdown-it-latex/dist/index.css'

getDefaultMdInstance = ->
  markdownIt
    html: true
    linkify: true
    typographer: true
    quotes: '„“‚‘'
  .use latex

export MarkdownDisplay = ({markdown = '', contentClass, markdownItInstance = getDefaultMdInstance()}) ->
  <div
    dangerouslySetInnerHTML={__html: markdownItInstance.render(markdown)}
    className={contentClass}
  />