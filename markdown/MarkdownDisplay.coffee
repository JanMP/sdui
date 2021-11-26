import React from 'react'
import markdownIt from 'markdown-it'
# import container from 'markdown-it-container'
# import mark from 'markdown-it-mark'
# import footnote from 'markdown-it-footnote'
# import emoji from 'markdown-it-emoji'
# import deflist from 'markdown-it-deflist'
# import ins from 'markdown-it-ins'
# import sub from 'markdown-it-sub'
# import sup from 'markdown-it-sup'
# import abbr from 'markdown-it-abbr'
# import {default as anchor} from 'markdown-it-anchor'
# import {default as tocDoneRight} from 'markdown-it-toc-done-right'
# import customBlock from 'markdown-it-custom-block'
# import katex from 'markdown-it-katex'

# const tocOptions = {
#     containerClass: 'help-nav',
#     level: [1, 2],
#     listType: 'ul'
#   };
  
# const customBlocks = {
#   helpContent: function(content) {
#     return `<div class='help-content'>${content}</div>`;
#   }
# };
  
getDefaultMdInstance = ->
  markdownIt
    html: true
    linkify: true
    typographer: true
    quotes: '„“‚‘'

  
export MarkdownDisplay = ({markdown = '', contentClass, markdownItInstance = getDefaultMdInstance()}) ->
  <div dangerouslySetInnerHTML={__html: markdownItInstance.render(markdown)} className={contentClass} />


