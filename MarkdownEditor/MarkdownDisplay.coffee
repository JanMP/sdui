import React from 'react'
import markdownIt from 'markdown-it'
import container from 'markdown-it-container'
import {tw} from '/imports/ui/twind'
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
  
md =
  markdownIt
    html: true
    linkify: true
    typographer: true
    quotes: '„“‚‘'
  .use container, 'search-tip',
    render: (tokens, idx) ->
      if tokens[idx].nesting is 1
        "<div class='search-tip'>
          <div>
            <img src='/images/Lupe.svg' alt='search-tip'/>
          </div>
          <div>"
      else
        "</div></div>"
  .use container, 'logo'

  
export default ({markdown = '', style = {}, contentClass}) ->
  <div dangerouslySetInnerHTML={__html: md.render(markdown)} style={style} className={contentClass} />


