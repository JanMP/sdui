# Write your package code here!
import React, {Suspense, lazy} from 'react'

suspend = (WrappedComponent) -> (props) ->
  <Suspense fallback={<div>Loading...</div>}><WrappedComponent {props...}/></Suspense>

# Variables exported by this module can be imported by other packages and
# applications. See sdui-tests.js for an example of importing.
export {
  userWithIdIsInRole, currentUserIsInRole,
  useCurrentUserIsInRole, currentUserMustBeInRole,
  scopesForCurrentUserInRole, useScopesForCurrentUserInRole
} from './common/roleChecks.coffee'
export {useSession} from './common/useSession.coffee'
export {meteorApply} from './common/meteorApply.coffee'
export {config, useConfig, Configurations} from './config/config.coffee'
export {default as connectFieldWithLabel} from './forms/connectFieldWithLabel.coffee'

export {createTableDataAPI} from './api/createTableDataAPI.coffee'
export {createUserTableAPI} from './usertable/createUserTableAPI.coffee'
export {createChatAPI} from './chat/createChatAPI.coffee'
export {regExpMessages_de, de, setDefaultValidationMessages} from './api/validationMessages.coffee'
# export {createFilesAPI, filesAPISourceSchema} from './api/createFilesAPI.coffee'

# server only (eventually)
export {default as queryUiObjectToQuery} from './query-editor/queryUiObjectToQuery.coffee'

export ActionButton = suspend lazy -> import('./forms/ActionButton.coffee').then (m) -> default: m.ActionButton
export SdList = suspend lazy -> import('./tables/SdList.coffee').then (m) -> default: m.SdList
export SdTable = suspend lazy -> import('./tables/SdTable.coffee').then (m) -> default: m.SdTable
export SdContentEditor = suspend lazy -> import('./tables/SdContentEditor.coffee').then (m) -> default: m.SdContentEditor
export SdEditor = suspend lazy -> import('./editor/SdEditor.coffee').then (m) -> default: m. SdEditor
export MarkdownDisplay = suspend lazy -> import('./markdown/MarkdownDisplay.coffee').then (m) -> default: m.MarkdownDisplay
export ColorPicker = suspend lazy -> import('./forms/ColorPicker.coffee').then (m) -> default: m. ColorPicker
export ColorPickerField = suspend lazy -> import('./forms/ColorPicker.coffee').then (m) -> default: m.ColorPickerField
export RatingField = suspend lazy -> import('./forms/RatingField.coffee').then (m) -> default: m.RatingField
export ThumbsField = suspend lazy -> import('./forms/ThumbsField.coffee').then (m) -> default: m.ThumbsField
export ThumbsTableField = suspend lazy -> import('./forms/ThumbsField.coffee').then (m) -> default: m.ThumbsTableField
export LinkField = suspend lazy -> import('./forms/LinkField.coffee').then (m) -> default: m.LinkField
export LinkTableField = suspend lazy -> import('./forms/LinkField.coffee').then (m) -> default: m.LinkTableField
export * from './forms/uniforms-custom/select-implementation'
export ManagedForm = suspend lazy -> import('./forms/ManagedForm.coffee').then (m) -> default: m.ManagedForm
export FormModal = suspend lazy -> import('./forms/FormModal.coffee').then (m) -> default: m.FormModal
export LoginForm = suspend lazy -> import('./login-forms/LoginForm.coffee').then (m) -> default: m.LoginForm
export LoginButton = suspend lazy -> import('./login-forms/LoginButton.coffee').then (m) -> default: m.LoginButton

export QueryEditor = suspend lazy -> import('./query-editor/QueryEditor.coffee').then (m) -> default: m.QueryEditor
export QueryEditorField = suspend lazy -> import('./query-editor/QueryEditorField.coffee').then (m) -> default: m.QueryEditorField
export SdDocumentSelect = suspend lazy -> import('./tables/SdDocumentSelect.coffee').then (m) -> default: m.SdDocumentSelect
export SdDocumentSelectField = suspend lazy -> import('./tables/SdDocumentSelect.coffee').then (m) -> default: m.SdDocumentSelectField
export SdChat = suspend lazy -> import('./chat/SdChat.coffee').then (m) -> default: m.SdChat

export Gravatar = suspend lazy -> import('./forms/GravatarField.coffee').then (m) -> default: m.Gravatar
export GravatarField = suspend lazy -> import('./forms/GravatarField.coffee').then (m) -> default: m.GravatarField