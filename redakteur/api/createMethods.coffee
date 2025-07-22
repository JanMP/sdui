import {Meteor} from 'meteor/meteor'
import {ValidatedMethod} from 'meteor/mdg:validated-method'
import {Schema, SdMethod} from 'meteor/janmp:sdui'
import {RSSParser} from 'rss-parser'
import {articleToPromptTag} from './articleToPromptTag.coffee'

export createMethods = ({
sourceName
articleCategories
articleGenerationSchema
generateArticleMainPrompt
retentionDays
creationParamsSchema
generatedArticlesDataOptions
promptsDataOptions
researchedArticlesDataOptions
rssFeedsDataOptions
}) ->

  ResearchedArticles = researchedArticlesDataOptions.collection


  metaDataValidate = (new Schema articleGenerationSchema).validate
  writeMetaDataTool =
    type: 'function'
    function:
      name: 'writeMetaData'
      description: 'Write the structured meta data for the article'
      parameters: articleGenerationSchema

  retentionDays ?= 21

  dateSinceDaysAgo = (sinceDaysAgo) ->
    now = new Date()
    new Date(now.setDate(now.getDate() - sinceDaysAgo))

  # mainTextLLM = if Meteor.isServer
  #   setupChatModel Meteor.settings["#{sourceName}.writeArticleLLM"]
  # structuredMetaDataLLM = if Meteor.isServer
  #   setupChatModel Meteor.settings["#{sourceName}.writeMetaDataLLM" ? Meteor.settings"#{sourceName}.writeArticleLLM"]
  #   .bindTools [writeMetaDataTool], tool_choice: 'writeMetaData'

  ###*
    @param {Object} params
    @param {String} params.context
    @param {String} [params.writePrompt]
    @param {String} [params.stylePrompt]
    @param {String} [params.baseArticleId]
    ###
  writeArticleWithContext = ({context, writePrompt = defaultWritePrompt, stylePrompt = "", baseArticleId}) ->
    return unless Meteor.isServer
    try
      mainTextContext = [
        new SystemMessage writePrompt + '/n/n' + stylePrompt
        new HumanMessage context
      ]
      mainText  = (await mainTextLLM.invoke mainTextContext)?.content ? '[missing mainText]'

      metaDataContext = [
        mainTextContext...
        new AIMessage mainText
        new HumanMessage 'Now generate the meta data for the article.'
      ]

      for tries in [1..5]
        result = await structuredMetaDataLLM.invoke metaDataContext
        metaData = result?.tool_calls?[0]?.args
        break if metaDataValidate metaData
        console.log '[writeArticle] metaData not valid, retrying', tries

        # Don't directly wrap the entire result in an AIMessage
        # Instead, use a human message to communicate the validation errors
        errorMessage = "The metadata was invalid. Please try again with these requirements: " + JSON.stringify(metaDataValidate.errors)
        metaDataContext.push new HumanMessage errorMessage

      generatedArticle = {metaData..., haupttext: mainText}
      await GeneratedArticles.insertAsync
        uuid: generateUUID()
        title: generatedArticle?.ueberschrift
        teaser: generatedArticle?.teaser
        content: generatedArticle?.haupttext
        createdAt: new Date()
        rawOutput: generatedArticle
        basedOnArticleId: baseArticleId
        articleLinks: generatedArticle?.links
        context: context
    catch error
      console.error "[writeArticle] error: #{error}"
      throw error

  writeArticleBasedonArticle = ({baseArticle, minArticles = 2}) ->

    enoughSimilarArticles = baseArticle.similarArticles.length >= minArticles
    useWithoutCorroboration = baseArticle.feedMetaData.useWithoutCorroboration
    return unless enoughSimilarArticles or useWithoutCorroboration

    console.log 'writeArticleBasedonArticle', baseArticle.title
    similarArticleIds = baseArticle.similarArticles.map (a) -> a._id
    stylePrompt = await Prompts.findOneAsync {promptType: baseArticle.articleCategory}

    similarArticles =
      await ResearchedArticles.find _id: $in: similarArticleIds,
        sort: pubDate: -1
        fields:
          title: 1
          pubDate: 1
          link: 1
          content: 1
          feedMetaData: 1
      .fetchAsync()
    articleTags =
      similarArticles
      .map articleToPromptTag
      .join '\n'
    # console.log 'articleTags', articleTags
    writeArticleWithContext
      context: articleTags
      stylePrompt: stylePrompt
      baseArticleId: baseArticle._id





  writeArticles = ({sinceDaysAgo}) ->

    getNextArticle = ({minDate}) ->
      ResearchedArticles.findOneAsync
        usable: true
        used: false
        "similarArticles.0": "$exists": true
        pubDate: $gte: minDate
      ,
        sort: pubDate: -1


    minDate = dateSinceDaysAgo sinceDaysAgo

    console.log "[writeArticles] write new Articles for sources published since #{minDate}"

    article = await getNextArticle({minDate})
    while article?
      try
        await writeArticleBasedonArticle(baseArticle: article, minArticles: 3)
        # we mark the articles as used
        usedArticleIds = article.similarArticles?.map ({_id}) -> _id
        await ResearchedArticles.updateAsync {_id: $in: usedArticleIds ? []}, {$set: used: true}, {multi: true}
      catch error
        console.error error
      finally
        # we mark the artice as used but not the other similar ones
        await ResearchedArticles.updateAsync {_id: article._id}, {$set: used: true}
        article = await getNextArticle({minDate})

  # categorizer = if Meteor.isServer
  #   setupChatModel Meteor.settings.MacRedakteur.catetgorizeArticleLLM
  #   .withStructuredOutput z.object
  #     usable: z.boolean()
  #     articleCategory: z.enum(articleCategories)

  categorizeArticle = (article) ->
    return unless Meteor.isServer
    return if article.articleCategory? # we already did this

    prompt =
      [
        new SystemMessage """
          You are a helpful assistant that categorizes articles.
          You will be given the title and content of an article.
          1. Determine if the article is usable for publication in a Magazine about the topics Apple, Macintosh or Iphone. Exclude articles that are aimed at the US market or any kind of Deals.
          2. Determine the primary category of the article.
          """
      ,
        new HumanMessage """
          Title:
          #{article.title}
          Content:
          #{article.content}
          """
      ]

    try
      output = await categorizer.invoke prompt
      await ResearchedArticles.updateAsync _id: article._id,
        $set:
          usable: output.usable
          articleCategory: output.articleCategory
          used: false
    catch error
      console.error '[categorizeArticle] ', error


  importRssFeed = ({feed}) ->
    console.log 'importRssFeed', feed?.title
    parser = new RSSParser()
    parser.parseURL feed.url
    .then (feedContent) ->
      recentContent = feedContent.items.filter (item) ->
        (new Date item.pubDate) > dateSinceDaysAgo retentionDays
      await ResearchedArticles.rawCollection().bulkWrite recentContent.map (item) ->
        item.pubDate = new Date item.pubDate
        item.importDate = new Date()
        item.feedMetaData = feed
        updateOne:
          filter: {link: item.link}
          update: $set: item
          upsert: true
      ResearchedArticles.removeAsync pupDate: $lt: dateSinceDaysAgo retentionDays
    .catch (error) -> console.error '[importRssFeed]', error.message


  addSimilarArticles = (article) ->
    unless article.sdai?.vector
      throw new Meteor.Error '[addSimilarArticles] article needs a vector'
    await sdai.knnFindDocuments
      vector: article.sdai.vector
      limit: 20
    .then (similarArticles) ->
      # we don't filter out the article itself, we'd later have to add it back into the context
      _(similarArticles)
      .map (item) -> _.pick item, ['_id', 'title', 'link', 'pubDate', 'score']
      .filter ({pubDate}) -> pubDate <= article.pubDate
      .filter ({score}) -> score > 0.9
      .value()
    .then (similarArticles) ->
      await ResearchedArticles.updateAsync {_id: article._id}, {$set: {similarArticles}}
    .catch (error) -> console.error '[addSimilarArticles] ', error

  getFeeds = -> RssFeeds.find({use: true}).fetchAsync()


  updateFeeds = ->
    console.log 'updateFeeds'
    unless onlyWriteArticles = false
      feeds = await getFeeds()
      for feed in feeds
        await importRssFeed {feed}
      articlesToProcess =
        await ResearchedArticles.find(usable: $exists: false).fetchAsync()
        .catch (error) ->
          console.error '[updateFeeds] ', error
      # Pass 1: categorize and update embedding
      for article in articlesToProcess
        try
          console.log '[updateFeeds] process: ', article.title
          await categorizeArticle article
          # we assume articles didn't change, so we are fine with only updating embedding the first time
          await sdai.updateEmbeddingForDocumentWithId id: article._id
        catch error
          console.error '[updateFeeds] ', error
      # Pass 2: add similar articles to each usable but unused article
      articlesToProcess =
        await ResearchedArticles.find
          usable: true
          used: false
          importDate: $gt: dateSinceDaysAgo 7
          'sdai.vector': $exists: true
        .fetchAsync()
      for article in articlesToProcess
        console.log '[updateFeeds] find similar articles for: ', article.title
        try
          await addSimilarArticles article
        catch error
          console.error '[updateFeeds] ', error
      # Pass 3 Filter changes with every interation
    await writeArticles sinceDaysAgo: 14

  new ValidatedMethod
    name: "#{sourceName}.generatedArticles.publish"
    validate:
      new Schema
        type: 'object'
        properties:
          id: type: 'string'
      .methodValidator
    run: ({id}) ->
      return unless Meteor.isServer
      try
        article = await GeneratedArticles.findOneAsync id
        unless article
          throw new Meteor.Error 'not-found', 'Article not found'
        console.log data = {uuid: article.uuid, article.rawOutput...}
        fetch 'https://www.maclife.de/api/v2/ai/article',
          method: 'POST'
          headers:
            Authorization: 'Bearer a9d10999fa718ba8a243'
            'Content-Type': 'application/json'
          body: JSON.stringify data
        .then (response) ->
          await GeneratedArticles.updateAsync id,
            $set: published: true
        .then console.log


  new ValidatedMethod
    name: "#{sourceName}.generatedArticles.create"
    validate: creationParamsSchema.methodValidator
    run: ({prompt, articleType}) ->
      stylePrompt = await Prompts.findOneAsync {promptType: articleType}
      sdai = researchedArticlesDataOptions?.sdai
      vector =  await sdai.embeddingFromContext context: prompt
      articlesForPrompt = await sdai.knnFindDocuments {vector, limit: 20}
      context =
        articlesForPrompt
        .map articleToPromptTag
        .join '\n\n'
      writePrompt = """
        #{defaultWritePrompt}

        # Zusätzliche Anweisungen für diese Aufgabe:
        #{prompt}
      """
      writeArticleWithContext {context, writePrompt, stylePrompt}




  new ValidatedMethod
    name: "#{sourceName}.generatedArticles.getArticleById"
    validate:
      new Schema
        type: 'object'
        properties:
          id: type: 'string'
      .methodValidator
    run: ({id}) ->
      return unless Meteor.isServer
      GeneratedArticles.findOneAsync id
