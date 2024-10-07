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


## SdTable

- this creates a customizable reactive data table. With the configuration options, the table can be made filterable, searchable, and editable.
- Components such as `SdChatLog` use the `SdTable` under the hood.

## createAppLayoutAPI

- This function can be used to create the layout for an app.
- For this, it receives an array of sources (react components) that will be made available to the user via a sidebar.
- Each source needs to specify a label (e.g. 'Home'), the path (e.g. '/home') an icon, which roles have access to the path the react component that will get rendered.
- Additionally, each source can have itself items that will become nested paths.
- note that the function only returns the `dataOptions` object.
- this object then needs to be passed to `SdAppLayout` to create the actual routes.