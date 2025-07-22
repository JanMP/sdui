export articleToPromptTag = ({title, pubDate, feedMetaData, link, content}) ->
  """
    <article>
      title: #{title}
      published: #{pubDate}
      trust: #{feedMetaData?.trustScore}
      link: #{link}
      #{content}
    </article>
  """