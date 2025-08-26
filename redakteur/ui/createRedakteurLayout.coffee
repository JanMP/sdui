import { createResearchedArticlesStatisticsTableAPI } from '../api/ResearchedArticlesStatistics.coffee'
import React from 'react'
import {createGeneratedArticlesPage} from './GeneratedArticlesPage'
import {createResearchedArticlesPage} from './ResearchedArticlesPage'
import {createPromptsPage} from './PromptsPage'
import {createRssFeedsPage} from './RssFeedsPage'
import {createResarchedArticlesStatisticsPage} from './ResearchedArticlesStatisticsPage'



export createRedakteurLayout = ({sourceName, label, path, role, dataOptions}) ->
  RssFeedsPage = createRssFeedsPage({dataOptions: dataOptions.rssFeedsDataOptions})
  PromptsPage = createPromptsPage({dataOptions: dataOptions.promptsDataOptions})
  ResearchedArticlesPage = createResearchedArticlesPage({dataOptions: dataOptions.researchedArticlesDataOptions})
  GeneratedArticlesPage = createGeneratedArticlesPage {
    sourceName, path,
    dataOptions: dataOptions.generatedArticlesDataOptions,
    creationParamsSchema: dataOptions.creationParamsSchema
  }
  ResearchedArticlesStatisticsPage = createResarchedArticlesStatisticsPage({dataOptions: dataOptions.researchedArticlesStatisticsDataOptions})

  label: label
  path: path
  icon: 'pi pi-fw pi-folder'
  role: role
  hideOnDisabled: true
  items: [
    label: 'RSS Feeds', icon: 'pi pi-fw pi-table', path: 'rss-feeds', element: <RssFeedsPage/>
  ,
    label: 'Prompts für Artikeltypen', icon: 'pi pi-fw pi-table', path: 'prompts', element: <PromptsPage />
  ,
    label: 'Recherchierte Artikel', icon: 'pi pi-fw pi-table', path: 'researched-articles', element: <ResearchedArticlesPage />
  ,
    label: 'Produzierte Artikel', icon: 'pi pi-fw pi-table', path: 'produced-articles', element: <GeneratedArticlesPage />
  ,
    disabled: true, hideOnDisabled: true, label: 'Produzierter Artikel', icon: 'pi pi-fw pi-table', path: 'produced-articles/:articleId', element: <GeneratedArticlesPage />
  ,
    label: 'Statistiken zu recherchierten Artikeln', icon: 'pi pi-fw pi-table', path: 'researched-articles-statistics', element: <ResearchedArticlesStatisticsPage />
  ]
