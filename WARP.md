# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Table of Contents

1. [Package Overview & Architecture](#package-overview--architecture)
2. [Development Commands](#development-commands)
3. [Core Components & API Generators](#core-components--api-generators)
4. [Schema System & Role-Based Access Control](#schema-system--role-based-access-control)
5. [Testing Strategy](#testing-strategy)
6. [CoffeeScript & TypeScript Conventions](#coffeescript--typescript-conventions)
7. [AI Integration & LangGraph](#ai-integration--langgraph)
8. [Package Structure](#package-structure)

## Package Overview & Architecture

**janmp:sdui** (Schema Driven UI) is a comprehensive Meteor package that provides high-level React components and backend API generators for rapid application development. The package follows a schema-first approach where data structures drive both UI rendering and backend API generation.

### Core Architecture

```
Schema Definition → API Generator → Backend (Methods/Publications) → UI Components
                                      ↓
                               MongoDB Collection ↔ Reactive DDP ↔ Client Components
```

### Key Principles

- **Schema-Driven**: All components and APIs are generated from JSON Schema definitions
- **Role-Based Access**: Built-in integration with `alanning:roles` for fine-grained permissions
- **Reactive Data Flow**: Leverages Meteor's DDP for real-time data synchronization
- **Component Composition**: Higher-order functions create complete CRUD interfaces
- **AI-First**: Integrated LLM support via LangGraph and multiple AI providers

## Development Commands

### Package Development

```bash
# Run tests (uses Meteor's tinytest runner)
meteor test-packages ./ --driver-package meteortesting:mocha

# Run specific test file
meteor test-packages ./ --driver-package meteortesting:mocha --grep "TextEmbeddingModel"

# Lint CoffeeScript files
coffeelint .

# TypeScript type checking
tsc --noEmit

# Publish package (after version bump in package.js)
meteor publish
```

### Testing Individual Components

```bash
# Run workspace API tests
meteor test-packages ./ --driver-package meteortesting:mocha --grep "WorkspaceAPI"

# Run AI-related tests
meteor test-packages ./ --driver-package meteortesting:mocha --grep "TextEmbeddingModel"
```

## Core Components & API Generators

### Component → API Generator Matrix

| UI Component | API Generator | Purpose |
|-------------|---------------|---------|
| `SdTable` | `createTableDataAPI` | Data tables with CRUD operations |
| `SdContentEditor` | `createTableDataAPI` | Rich content editing forms |
| `SdList` | `createTableDataAPI` | List views with filtering |
| `SdChat` | `createChatAPI` | Multi-user/bot chat interfaces |
| `SdChatLog` | `createChatLogAPI` | Chat session management |
| `SdAppLayout` | `createAppLayoutAPI` | Application routing & navigation |
| `SdUserTable` | `createUserTableAPI` | User management interface |

### Primary API Generators

#### createTableDataAPI

Creates complete CRUD operations for any data type:

```coffeescript
dataOptions = createTableDataAPI
  sourceName: 'my-table'
  sourceSchema: mySchema
  collection: MyCollection
  canEdit: true
  canAdd: true
  canDelete: true
  viewTableRole: 'user'
  editRole: 'editor'
```

**Generated Server Artifacts:**
- Methods: `{sourceName}.submit`, `{sourceName}.delete`, `{sourceName}.fetchFormData`
- Publications: `{sourceName}.rows`
- Reactive aggregation pipelines with search, sort, filter support

#### createChatAPI

Generates complete chat system with optional bot integration:

```coffeescript
chatOptions = createChatAPI
  sourceName: 'my-chat'
  messageCollection: Messages
  sessionListCollection: Sessions
  viewChatRole: 'user'
  bots: [myBot]  # Optional bot integrations
```

**Generated Server Artifacts:**
- Methods: `{sourceName}.addMessage`, `{sourceName}.addSession`, `{sourceName}.setFeedBackForMessage`
- Publications: `{sourceName}.messages`, `{sourceName}.sessionList`, `{sourceName}.metaData`

#### createChatBot

Creates LLM-powered chatbots with tool support:

```coffeescript
bot = createChatBot
  chatClient: openAiClient  # LangChain chat model
  getSystemPrompt: -> "You are a helpful assistant"
  getTools: ({sessionId}) -> [myTool1, myTool2]
  messageCollection: Messages
```

## Schema System & Role-Based Access Control

### Schema Definition

The package uses a custom `Schema` class extending JSON Schema:

```coffeescript
schema = new Schema
  type: 'object'
  properties:
    title:
      type: 'string'
      title: 'Article Title'
    content:
      type: 'string'
      sdContent: isContent: true  # Custom UI hints
    priority:
      type: 'number'
      minimum: 1
      maximum: 5
  required: ['title']
```

### Role-Based Access Control

Uses `alanning:roles` with helper functions:

```coffeescript
# Role checking helpers
currentUserIsInRole('editor', 'my-scope')
useCurrentUserIsInRole('admin')  # React hook
currentUserMustBeInRole('moderator')  # Throws if not authorized

# Scope-based permissions
viewTableRole: {scope: 'my-app', role: 'user'}
editRole: {scope: 'my-app', role: 'editor'}
```

### Common Role Patterns

- `'any'` - No authentication required
- `'user'` - Any logged-in user
- `{scope: 'app', role: 'editor'}` - Scoped role requirements
- Function returning role based on context

## Testing Strategy

### Test Structure

Tests are organized using Mocha/Chai with Meteor-specific patterns:

```coffeescript
import {expect} from 'chai'
import {MyComponent} from './MyComponent.coffee'

if Meteor.isServer
  describe 'MyComponent', ->
    beforeEach ->
      @collection = new Mongo.Collection null  # In-memory collection
      
    it 'should handle data correctly', ->
      result = MyComponent.processData({test: 'data'})
      expect(result).to.be.an('object')
```

### Testing Locations

- `workspace/WorkspaceAPI.test.coffee` - Workspace API functionality
- `ai/TextEmbeddingModel.test.coffee` - AI/ML model testing
- `api/createDefaultPipeline.test.coffee` - Data pipeline testing
- `sdui-tests.js` - Main test entry point

### Testing Conventions

- Use `Meteor.isServer` guards for server-only tests
- Create in-memory collections with `new Mongo.Collection null`
- Use Sinon for mocking external APIs
- Test both success and error cases

## CoffeeScript & TypeScript Conventions

### CoffeeScript Style (from coffeelint.json)

- **Indentation**: 2 spaces, no tabs
- **Line length**: 120 characters max
- **Arrow functions**: Use fat arrows (`=>`) for bound context
- **Classes**: CamelCase class names required
- **Operators**: Prefer English operators (`and`, `or`, `not`)

### File Structure

```coffeescript
# Imports at top
import {Meteor} from 'meteor/meteor'
import {Schema} from './Schema.coffee'

# Constants
DEFAULT_OPTIONS = 
  canEdit: false
  canAdd: true

# Main function/class
export createMyAPI = (options) ->
  {sourceName, collection, schema} = options
  # Implementation...
```

### TypeScript Integration

- Type declarations in `typeDeclarations.d.ts`
- Mixed usage: CoffeeScript for logic, TypeScript for complex types
- Custom types in `customTypes.ts`

## AI Integration & LangGraph

### AI Architecture

The package includes extensive AI/LLM integration:

- **LangGraph**: Agent workflow orchestration
- **Multiple Providers**: OpenAI, Anthropic, Mistral support
- **Tool System**: `SdMethod` creates LLM-callable tools
- **Vector Search**: Qdrant integration for semantic search

### Key AI Components

- `LangGraphChatBot`: Advanced agent-based chat
- `TextEmbeddingModel`: Text embedding generation
- `SdMethod`: Creates structured tools for LLMs
- `SdToolRegistry`: Manages available tools

### SdMethod Tool Creation

```coffeescript
new SdMethod
  name: 'searchDocuments'
  schema: searchSchema
  role: 'user'
  tool:
    agentRole: {scope: 'app', role: 'agent'}
  run: (args) ->
    # Tool implementation
    return results: searchResults
```

## Package Structure

### Main Entry Points

- `sdui-client.coffee` - Client-side exports (static)
- `sdui-client-dynamic.coffee` - Client-side with lazy loading
- `sdui-server.coffee` - Server-side exports
- `package.js` - Meteor package definition

### Key Directories

- `api/` - Core API generators and backend utilities
- `chat/` - Chat system components and generators
- `forms/` - Form components and field types
- `tables/` - Data display components (tables, lists, editors)
- `ai/` - AI/LLM integration components
- `workspace/` - Document workspace functionality
- `common/` - Shared utilities and helpers
- `schema/` - Custom Schema system

### Configuration Files

- `coffeelint.json` - CoffeeScript linting rules
- `tsconfig.json` - TypeScript configuration
- `package-types.json` - Package type declarations entry point

### Development Files

- `dev-notes/docu.md` - Package documentation
- Test files: `*.test.coffee` scattered throughout modules