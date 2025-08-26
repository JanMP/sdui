import {Meteor} from 'meteor/meteor'
import {invokeLangGraphAgent, Schema, SdMethod, generateUUID} from 'meteor/janmp:sdui'
import RSSParser from 'rss-parser'
import {articleToPromptTag} from './articleToPromptTag.coffee'
import {Jobs} from 'meteor/msavin:sjobs'
import _ from 'lodash'


export createMethods = ({
sourceName
viewTableRole
editRole
articleCategories
articleGenerationSchema
articleGenerationMainPrompt
retentionDays
creationParamsSchema
generatedArticlesDataOptions
promptsDataOptions
researchedArticlesDataOptions
rssFeedsDataOptions
publishGeneratedArticle
createJobsSchedule
}) ->

  GeneratedArticles = generatedArticlesDataOptions.collection
  Prompts = promptsDataOptions.collection
  ResearchedArticles = researchedArticlesDataOptions.collection
  RssFeeds = rssFeedsDataOptions.collection

  retentionDays ?= 21

  dateSinceDaysAgo = (sinceDaysAgo) ->
    now = new Date()
    new Date(now.setDate(now.getDate() - sinceDaysAgo))

  getFeeds = -> RssFeeds.find({use: true}).fetchAsync()

  ###*
    @param {Object} params
    @param {String} params.context
    @param {String} [params.mainPrompt]
    @param {String} [params.articleTypePrompt]
    @param {String} [params.baseArticleId]
    ###
  writeArticleWithContext = ({context, mainPrompt = articleGenerationMainPrompt, articleTypePrompt, baseArticleId}) ->
    return unless Meteor.isServer
    try

      prompt =
        if articleTypePrompt
          """
            #{mainPrompt}

            # Zusätzliche Anweisungen für diese Aufgabe:
            #{articleTypePrompt}
          """
        else
          mainPrompt

      {result} = await invokeLangGraphAgent
        settings: Meteor.settings.langsmith
        agent: 'redakteur_agent'
        input: {context, prompt}

      await GeneratedArticles.insertAsync
        uuid: generateUUID()
        title: result?.ueberschrift
        teaser: result?.teaser
        content: result?.haupttext
        createdAt: new Date()
        rawOutput: result
        basedOnArticleId: baseArticleId
        articleLinks: result?.links
        context: context
    catch error
      console.error "[writeArticle] error: #{error}"
      throw error


  writeArticleBasedonArticle = ({baseArticle, minArticles = 1}) ->
    enoughSimilarArticles = baseArticle?.similarArticles?.length >= minArticles
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

    writeArticleWithContext
      context: articleTags
      stylePrompt: stylePrompt
      baseArticleId: baseArticle._id


  writeArticles = ({sinceDaysAgo}) ->

    getNextArticle = ({minDate}) ->
      ResearchedArticles.findOneAsync
        usable: true
        used: false
        pubDate: $gte: minDate
      ,
        sort: pubDate: -1


    minDate = dateSinceDaysAgo sinceDaysAgo

    console.log "[writeArticles] write new Articles for sources published since #{minDate}"

    article = await getNextArticle({minDate})
    while article?
      try
        await writeArticleBasedonArticle(baseArticle: article, minArticles: 0)
        # we mark the articles as used
        usedArticleIds = article.similarArticles?.map ({_id}) -> _id
        await ResearchedArticles.updateAsync {_id: $in: usedArticleIds ? []}, {$set: used: true}, {multi: true}
      catch error
        console.error error
      finally
        # we mark the artice as used but not the other similar ones
        await ResearchedArticles.updateAsync {_id: article._id}, {$set: used: true}
        article = await getNextArticle({minDate})


  categorizeArticle = (article) ->
    return unless Meteor.isServer
    return if article.articleCategory? # we already did this

    try
      {result} = await invokeLangGraphAgent
        settings: Meteor.settings.langsmith
        agent: 'categorize_article_redakteur'
        input:
          title: article.title
          content: article.content
          articleCategories: articleCategories

      console.log '[categorizeArticle] result', result

      if result?
        await ResearchedArticles.updateAsync {_id: article._id},
          $set:
            usable: result.usable ? false
            articleCategory: result.articleCategory or undefined
            used: false
    catch error
      console.error '[categorizeArticle] ', error
      throw new Meteor.Error '[categorizeArticle]', error.message


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
    await researchedArticlesDataOptions?.sdai.knnFindDocuments
      vector: article.sdai.vector
      limit: 20
    .then (similarArticles) ->
      # we don't filter out the article itself, we'd later have to add it back into the context
      _(similarArticles)
      .map (item) -> _.pick item, ['_id', 'title', 'link', 'pubDate', 'score', 'feedMetaData']
      .filter ({pubDate}) -> pubDate <= article.pubDate
      .filter ({score}) -> score > 0.9
      .value()
    .then (similarArticles) ->
      await ResearchedArticles.updateAsync {_id: article._id}, {$set: {similarArticles}}
    .catch (error) -> console.error '[addSimilarArticles] ', error


  updateFeeds = ->
    console.log 'updateFeeds'
    unless onlyWriteArticles = false
      feeds = await getFeeds()
      for feed in feeds
        await importRssFeed {feed}
      console.log '[updateFeeds] imported feeds'
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
          await researchedArticlesDataOptions?.sdai?.updateEmbeddingForDocumentWithId id: article._id
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

    await writeArticles sinceDaysAgo: 21


  if Meteor.isServer and false
    updateFeeds()


  new SdMethod
    name: "#{sourceName}.generatedArticles.publish"
    schema: new Schema
      type: 'object'
      properties:
        id: type: 'string'
    role: editRole
    run: ({id}) ->
      return unless Meteor.isServer
      try
        article = await GeneratedArticles.findOneAsync id
        unless article
          throw new Meteor.Error 'not-found', 'Article not found'
        console.log data = {uuid: article.uuid, article.rawOutput...}
        publishGeneratedArticle data
        .then (response) ->
          await GeneratedArticles.updateAsync id,
            $set: published: true



  new SdMethod
    name: "#{sourceName}.generatedArticles.create"
    schema: creationParamsSchema
    role: editRole
    run: ({prompt, articleType}) ->
      return unless Meteor.isServer
      articleTypePrompt = await Prompts.findOneAsync {promptType: articleType}
      sdai = researchedArticlesDataOptions?.sdai
      vector =  await sdai.embeddingFromContext context: prompt
      articlesForPrompt = await sdai.knnFindDocuments {vector, limit: 20}
      context =
        articlesForPrompt
        .map articleToPromptTag
        .join '\n\n'
      mainPrompt = """
        #{articleGenerationMainPrompt}

        # Zusätzliche Anweisungen für diese Aufgabe:
        #{prompt}
      """
      writeArticleWithContext {context, mainPrompt, articleTypePrompt}


  new SdMethod
    name: "#{sourceName}.generatedArticles.getArticleById"
    schema: new Schema
      type: 'object'
      properties:
        id: type: 'string'
    role: viewTableRole
    run: ({id}) ->
      return unless Meteor.isServer
      GeneratedArticles.findOneAsync id

  if Meteor.isServer
    Jobs.register
      "#{sourceName}.updateFeeds": ->
        console.log "#{new Date()} - Starting Job #{sourceName}.updateFeeds"
        updateFeeds()
        .then =>
          console.log "#{new Date()} - Finishing Job #{sourceName}.updateFeeds"
          schedule = createJobsSchedule()
          @replicate schedule
          @remove()
        .catch (error) =>
          @reschedule in: minutes: 20
          console.error "[#{sourceName}.updateFeeds] ", error.message
