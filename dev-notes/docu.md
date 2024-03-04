![Coding Pioneers](./cp.svg)

# plAIground ChatBot Documentation

## MeteorJS and the Direct Data Protocol (DDP)
**plAIground** is built with MeteorJS and makes heavy use of the meteor package `janmp:sdui` wich provides a toolbox with several reusable high-level UI components like tables, lists and content-editors, and generators for the backend functionality that feeds those components.

MeteorJS differs quite a bit from other Web Frameworks. You can find the Meteor Documentation at https://guide.meteor.com

For access from other Languages than JS/TS there are several libraries, most notably:
https://github.com/tanutapi/dart_meteor for Flutter
https://pypi.org/project/python-ddp/ for Python

This Documentation will show code examples for all necessary [subscriptions](https://guide.meteor.com/data-loading) and [method calls](https://guide.meteor.com/methods) in JS.

An easy way to see, what's going on between the Meteor Backend and the Client Application is the [Chrome MeteorJS Extension](https://chromewebstore.google.com/detail/ibniinmoafhgbifjojidlagmggecmpgf). Just point your Chrome browser at a page on a MeteorJS website, and you will be able to see the DDP data traffic, a list of active subscriptions and the contents of the clients datastore (Meteor offers a client side data store called Minimongo, that is automatically synced with the server side MongoDB via subscriptions, this datastore is designed to be accessed a lot like MongoDB itself).

### Subscription caveat
Meteor subscriptions data has to always be sorted and filtered on the client.

- Since Meteor only sends diffs of changed data, it is impossible to guarantee the sort order.
- If data items in a running subscription are swapped out, new data items are always added before the old ones are removed.
- If multiple instances of a subscription request different data (e.g. because the user has two browser windows with the same table but different search options opened), the data of both instances will be synced into the same client-side Minimongo collection. 

## janmp:sdui conventions
Method and subscription names in `janmp:sdui`often consist of a sourceName, that identifies all methods and subscriptions and the MongoDB/Minimongo collections, that belong together and the name of the method or subscription by functionality, (e.g `ZauberTopf.messages`or `ZauberMix.addMessage`). While `Meteor.call` and `Meteor.subscribe` are designed to take arrays of parameters, we hardly ever make use of that, but instead just take a single JS object as the sole parameter.

## Logging in
Hardly any subscription or method on **plAIground** is made available without logging in as a registered user with the appropriate [user roles](https://guide.meteor.com/accounts#alanning-roles). We use Meteor's  standard [password login](https://guide.meteor.com/accounts#accounts-password ). While it is possible to register new Users from the client app out of the box, the User account will in most cases have to be awarded with additional user roles, to access anything on **plAIground** or any other app that uses `janmp:sdui`.

## SdChat
SdChat is a UI component, that offers an interface for multi-user[^1] multi-session chats as well as single-user single-session chats (meant for use with a chat-bot).
In addition to a standard chat interface with support for [gravatar](https://gravatar.com) user icons and [markdown formatting](https://www.markdownguide.org) in chat-bubbles, it also provides a display bar for links to additional data.

## SdChat Subscriptions

### messages
Get the newest messages for a chat session:
`Meteor.subscribe('[sourceName].messages', [{sessionId: String}])`
The data will be synced into a collection with the same name `[sourceName].messages` with the following schema:
```coffeescript
userId:
	type: String
sessionId:
	type: String
createdAt: # while streaming, this will be constantly updated
	type: Date
text:
	type: String
chatRole: # only messages with 'user' and 'assisant' are published
	type: String
	allowedValues: ['user', 'assistant', 'system', 'log']
usage: # usage data from OpenAI
	type: Object
	optional: true
'usage.model':
	type: String
'usage.prompt':
	type: Number
'usage.completion':
	type: Number
workInProgress: # is set to true while streaming
	type: Boolean
	optional: true
feedback: # feedback data, that can be set by the client (see below)
	type: Object
	optional: true
'feedback.thumbs':
	type: String
	allowedValues: ['up', 'down']
	optional: true
'feedback.comment':
	type: String
	optional: true
```

### meta data 
Get the meta data for the chat session. The default MetaDataDisplay of SdChat is formatted to show a thumbnail with a title that links to an url on click, but the data field may contain anything. 
`Meteor.subscribe('[sourceName].metaData', [{sessionId}])`
Data synced to client-side collection named `'[sourceName].metaData'` with schema:
```coffeescript
sessionId: String
createdAt: Date
type: String # this tells you, what to expect in data
data:
	type: Object
	blackbox: true
```

### usageLimit
Get the usage limits for the chat session: `Meteor.subscribe('[sourceName].usageLimits', [{sessionId: String}])` The data will be synced into a collection with the same name `[sourceName].usageLimits` with the following schema:

```coffeescript
_id: String sessionId: String
maxMessageLength: Number
maxMessagesPerDay: Number
maxSessionsPerDay: Number
maxMessagesPerSession: Number
numberOfMessagesToday: Number
numberOfMessagesThisSession: Number
messagesPerDayLeft: Number
sessionsPerDayLeft: Number
messagesPerSessionLeft: Number
```

The usage limits are governed by the user roles. 

## SdChat Methods

### addMessage
Send a new message to the chat session:
`Meteor.call('[sourceName].addMessage', {text: String, sessionId: String})`
This method validates the input and checks if the user is in the session. It also checks if the message limits per day and per session are not exceeded and if the message length is within the allowed limit. If all checks pass, the message is inserted into the `[sourceName].messages` collection and a reaction to the new message is triggered.

### addLogMessage
Add a log message to the chat session:
`Meteor.call('[sourceName].addLogMessage', {text: String, sessionId: String})`
This method is currently turned off.

### setFeedBackForMessage
Set feedback for a message in the chat session:
`Meteor.call('[sourceName].setFeedBackForMessage', {messageId: String, feedback: Object})`
This method validates the input and checks if the user is in the session of the message. If all checks pass, the feedback is set for the message in the `[sourceName].messages` collection.

### addSession
Add a new chat session:
`Meteor.call('[sourceName].addSession', {title: String, userIds: Array})`
This method validates the input and checks if the user has the `addSessionRole`. It also checks if the session limit per day is not exceeded. If all checks pass, a new session is inserted into the `[sourceName].sessionList` collection and the `onNewSession` function is called.

### deleteSession
Delete a chat session:
`Meteor.call('[sourceName].deleteSession', {id: String})`
This method validates the input and checks if the user has the `addSessionRole`. If all checks pass, the session is archived in the `[sourceName].sessionList` collection and all messages and meta data for the session are archived in their respective collections.

### initialSessionForChat
Get the initial session for the chat:
`Meteor.call('[sourceName].initialSessionForChat')`
This method checks if the user has the `addSessionRole`. If there is an existing session for the user, it returns the session ID. Otherwise, it creates a new session and returns the session ID.

### resetSingleSession
Reset the single session for the chat:
`Meteor.call('[sourceName].resetSingleSession')`
This method checks if the user has the `viewChatRole`. If there is an existing session for the user, it archives the session and all messages and meta data for the session. Then it creates a new session and returns the session ID.

# Custom Implementations for Falkemedia
## sourceNames
We have (so far) implemented Server Functions and Web Interfaces for 2 Chat Bots, with the sourceName:
1. `ZauberMix`
2. `ZauberTopf`

## REST API
Users with access to the Chat Bots will have to be registered by Falkemedia, we have implemented a simple REST API to allow this. The `username` is used like an `id` in the context of the MobileClients and is never displayed in places where the user can see it.
### Register new User
POST Request to `<server-url>/api/users/add/<username>` with API-Key in `x-api-key`header. Registers a new User with role `falkemedia:free-user`. Returns `{username: String, password: String}`
### Delete User
DELETE Request to `<server-url>/api/users/remove/<username>` with API-Key in `x-api-key`header. Returns the number of Removed Users (i.e. 1).

## Methods
### setRole
Switch between user roles `free-user` and `paying-user`with scope `falkemedia`.
`Meteor.call('[sourceName].setRole, [{role: String}])`
This message allows the client to switch between those two roles, if the user is not in either of those roles, the method will throw an error. 

[^1]: as of 27.2.24 there is no built-in ui to manage users of a chat session, yet.
