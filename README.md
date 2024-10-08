# janmp:sdui

SchemaDrivenUI is a Meteor Package containing some high level React components and setup functions, to build an api to feed those components with data.

# Components


## SdChat
SdChat is a UI component, that offers an interface for multi-user[^1] multi-session chats as well as single-user single-session chats (meant for use with a chat-bot).
In addition to a standard chat interface with support for [gravatar](https://gravatar.com) user icons and [markdown formatting](https://www.markdownguide.org) in chat-bubbles, it also provides a display bar for links to additional data.

- you can create a new chat component by using the `SdChat` component giving it the dataOptions object obtained by createChatAPI.



## SdChatLog

- this can be used to create a chat log. The log consists of a filterable table where each row corresponds to a chat session. When clicking on the row, a window opens that shows the chat history for that session.

## createChatBot

- this is a helper function that creates a chatbot (e.g. anthropic or openai)
- it makes the API call to the underlying LLM provider and handles the response stream
- you can also give it an a function that returns an array of tools that will be made available to the LLM.


## createChatAPI

- this function can be called to create the necessary backend methods and publications.
- its return `dataOptions` can be used as parameter for SdChat.




## createAppLayoutAPI

- This function can be used to create the layout for an app.
- For this, it receives an array of sources (react components) that will be made available to the user via a sidebar.
- Each source needs to specify a label (e.g. 'Home'), the path (e.g. '/home') an icon, which roles have access to the path the react component that will get rendered.
- Additionally, each source can have itself items that will become nested paths.
- note that the function only returns the `dataOptions` object.
- this object then needs to be passed to `SdAppLayout` to create the actual routes.


## createTableDataAPI

- this function creates the backend methods and publications for updating data in a specific table.
- it returns `dataOptions` that can be used as props in the UI components for displaying the data.
- most importantly, we need to pass the schema object based on which the components and methods will be built.
- we then also need to pass the MongoDB collection where we want to store the information and what the name of the source is.
- Besides those parameters, there are many other parameters that control the behavior of the created component.


- Example Usge. First a schema and a mongodb collection is created. Then we can create components based on that schema.
```coffee
sourceSchema = new SimpleSchema
  markdown:
    type: String
    label: 'Markdown'
    sdContent: isContent: true
    uniforms: -> null
  title:
    type: String
    label: 'Titel'
  number:
    type: Number
    label: 'Eine Zahl'
  array:
    type: Array
    label: 'Personen'
  'array.$': Object
  'array.$.name': String
  'array.$.boolean':
    type: Boolean
    optional: true
    label: 'ist zu Allem bereit.'

ContentEditorTest = new Mongo.Collection 'content-editor-test'

dataOptions = createTableDataAPI
  sourceName: 'content-editor-test'
  sourceSchema: sourceSchema
  collection: ContentEditorTest
  canEdit: true
  canAdd: true
  canDelete: true
  canExport: true
  canUseQueryEditor: true
  canSort: true
  canSearch: true

export ContentEditor = ->
    <SdContentEditor dataOptions={dataOptions} />

export Table = ->
    <SdContentEditor dataOptions={dataOptions} />

export List = ->
    <SdContentEditor dataOptions={dataOptions} />
```

- This will result in the following components on the frontend: 
    - Content Editor: [ContentEditorExample](component-images/contentEditorExample.png)
    - Table: [tableExample](component-images/tableExample.png)
    - List: [listExample](component-images/listExample.png)