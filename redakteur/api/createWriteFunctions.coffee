import fetch from 'node-fetch'
import {tool} from '@langchain/core/tools'
import {HumanMessage, AIMessage, SystemMessage, ToolMessage} from '@langchain/core/messages'


export createWriteFunctions = ({
sourceName
articleGenerationSchema
generatedArticlesDataOptions
promptsDataOptions
researchedArticlesDataOptions
rssFeedsDataOptions
}) ->
