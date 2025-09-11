# Write your package code here!
import React, {Suspense, lazy} from 'react'

suspend = (WrappedComponent) -> (props) ->
  <Suspense fallback={<div>Loading...</div>}><WrappedComponent {props...}/></Suspense>

# Variables exported by this module can be imported by other packages and
# applications. See sdui-tests.js for an example of importing.
export {
  userWithIdIsInRole, currentUserIsInRole,
  useCurrentUserIsInRole, currentUserMustBeInRole,
  scopesForUserWithIdInRole, scopesForCurrentUserInRole, useScopesForCurrentUserInRole
} from './common/roleChecks.coffee'
export {useSession} from './common/useSession.coffee'
export {meteorApply} from './common/meteorApply.coffee'
export {config, useConfig, Configurations} from './config/config.coffee'
export {default as connectFieldWithLabel} from './forms/connectFieldWithLabel.coffee'
export {default as connectFieldPlus} from './forms/connectFieldPlus.coffee'
export {Schema} from './schema/Schema.coffee'
export {SdMethod} from './api/SdMethod.coffee'
export {createTableDataAPI} from './api/createTableDataAPI.coffee'
export {createUserTableAPI} from './usertable/createUserTableAPI.coffee'
export {createQAArticlesAPI} from './qa-articles/createQAArticlesAPI.coffee'
export {createChatAPI, chatSchema} from './chat/createChatAPI.coffee'
export {createChatAPI as createChatAPINext} from './chatNext/createChatAPI.coffee'
export {chatSchema as chatSchemaNext} from './chatNext/createChatAPI.coffee'
export {createRedakteurAPI} from './redakteur/api/createRedakteurAPI.coffee'
export {createRedakteurLayout} from './redakteur/ui/createRedakteurLayout.coffee'
export {createChatLogAPI, addCostsPipeline} from './chat/createChatLogAPI.coffee'
export {createAppLayoutAPI} from './app-layout/createAppLayoutAPI.coffee'
export {ToastProvider, useToast} from './app-layout/ToastProvider.coffee'
export {createJobsTableDataAPI} from './jobstable/createJobsTableDataAPI.coffee'
export {AppStatusPage, appIsOn} from './app-status/AppStatusPage.coffee'
export {generateUUID} from './common/generateUUID.coffee'
export {ErrorBoundary} from './common/ErrorBoundary.coffee'
export {SdWorkspaceAPI, WorkspaceInstance} from './workspace/SdWorkspaceAPI.coffee'
# export {createFilesAPI, filesAPISourceSchema} from './api/createFilesAPI.coffee'

# server only (eventually)

export ActionButton = suspend lazy -> import('./forms/ActionButton.coffee').then (m) -> default: m.ActionButton
export SdList = suspend lazy -> import('./tables/SdList.coffee').then (m) -> default: m.SdList
export SdTable = suspend lazy -> import('./tables/SdTable.coffee').then (m) -> default: m.SdTable
export DateDisplayTableComponent = suspend lazy -> import('./tables/DateDisplayTableComponent.coffee').then (m) -> default: m.DateDisplayTableComponent
export {DateDisplayTableComponentWithNullString} from './tables/DateDisplayTableComponent.coffee'
export SdContentEditor = suspend lazy -> import('./tables/SdContentEditor.coffee').then (m) -> default: m.SdContentEditor
export SdEditor = suspend lazy -> import('./editor/SdEditor.coffee').then (m) -> default: m. SdEditor
export MarkdownDisplay = suspend lazy -> import('./markdown/MarkdownDisplay.coffee').then (m) -> default: m.MarkdownDisplay
export ColorPicker = suspend lazy -> import('./forms/ColorPicker.coffee').then (m) -> default: m. ColorPicker
export ColorPickerField = suspend lazy -> import('./forms/ColorPicker.coffee').then (m) -> default: m.ColorPickerField
export RatingField = suspend lazy -> import('./forms/RatingField.coffee').then (m) -> default: m.RatingField
export Thumbs = suspend lazy -> import('./forms/ThumbsField.coffee').then (m) -> default: m.Thumbs
export ThumbsField = suspend lazy -> import('./forms/ThumbsField.coffee').then (m) -> default: m.ThumbsField
export ThumbsTableField = suspend lazy -> import('./forms/ThumbsField.coffee').then (m) -> default: m.ThumbsTableField
export LinkField = suspend lazy -> import('./forms/LinkField.coffee').then (m) -> default: m.LinkField
export LinkTableField = suspend lazy -> import('./forms/LinkField.coffee').then (m) -> default: m.LinkTableField
export * from './forms/uniforms-custom/select-implementation'
export ManagedForm = suspend lazy -> import('./forms/ManagedForm.coffee').then (m) -> default: m.ManagedForm
export FormModal = suspend lazy -> import('./forms/FormModal.coffee').then (m) -> default: m.FormModal
export LoginForm = suspend lazy -> import('./login-forms/LoginForm.coffee').then (m) -> default: m.LoginForm
export LoginButton = suspend lazy -> import('./login-forms/LoginButton.coffee').then (m) -> default: m.LoginButton
export FeedbackButton = suspend lazy -> import('./forms/FeedbackButtonField.coffee').then (m) -> default: m.FeedbackButton
export FeedbackButtonField = suspend lazy -> import('./forms/FeedbackButtonField.coffee').then (m) -> default: m.FeedbackButtonField
export FeedbackButtonTableField = suspend lazy -> import('./forms/FeedbackButtonField.coffee').then (m) -> default: m.FeedbackButtonTableField
export SdDocumentSelect = suspend lazy -> import('./tables/SdDocumentSelect.coffee').then (m) -> default: m.SdDocumentSelect
export SdDocumentSelectField = suspend lazy -> import('./tables/SdDocumentSelect.coffee').then (m) -> default: m.SdDocumentSelectField
export SdChat = suspend lazy -> import('./chat/SdChat.coffee').then (m) -> default: m.SdChat
export SdChatNext = suspend lazy -> import('./chatNext/SdChat.coffee').then (m) -> default: m.SdChat
export SdChatLog = suspend lazy -> import('./chat/SdChatLog.coffee').then (m) -> default: m.SdChatLog
export SdAppLayout = suspend lazy -> import('./app-layout/SdAppLayout.coffee').then (m) -> default: m.SdAppLayout
export Gravatar = suspend lazy -> import('./forms/GravatarField.coffee').then (m) -> default: m.Gravatar
export GravatarField = suspend lazy -> import('./forms/GravatarField.coffee').then (m) -> default: m.GravatarField
export FormattedJSON = suspend lazy -> import('./misc-components/FormattedJSON.coffee').then (m) -> default: m.FormattedJSON
export SdUserTable = suspend lazy -> import('./usertable/SdUserTable.coffee').then (m) -> default: m.SdUserTable
export SdJobsTable = suspend lazy -> import('./jobstable/SdJobsTable.coffee').then (m) -> default: m.SdJobsTable
export SdWorkspace = suspend lazy -> import('./workspace/SdWorkspace.coffee').then (m) -> default: m.SdWorkspace
export {runTests} from './runTests.coffee'