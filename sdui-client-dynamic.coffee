# Write your package code here!
import React, {Suspense, lazy} from 'react'

suspend = (WrappedComponent) -> (props) ->
  <Suspense fallback={-> <div>Loading...</div>}><WrappedComponent {props...}/></Suspense>

# Variables exported by this module can be imported by other packages and
# applications. See sdui-tests.js for an example of importing.
export {
  userWithIdIsInRole, currentUserIsInRole,
  useCurrentUserIsInRole, currentUserMustBeInRole,
  scopesForCurrentUserInRole, useScopesForCurrentUserInRole
} from './common/roleChecks.coffee'
export {useSession} from './common/useSession.coffee'
export {meteorApply} from './common/meteorApply.coffee'
export {config} from './config/config.coffee'
export {default as connectFieldWithLabel} from './forms/connectFieldWithLabel.coffee'

export {createTableDataAPI} from './api/createTableDataAPI.coffee'
export {createUserTableAPI} from './usertable/createUserTableAPI.coffee'
# export {createFilesAPI, filesAPISourceSchema} from './api/createFilesAPI.coffee'

# server only (eventually)
export {default as queryUiObjectToQuery} from './query-editor/queryUiObjectToQuery.coffee'

export ActionButton = suspend lazy -> import('./forms/ActionButton.coffee').then (m) -> default: m. ActionButton
export SdList = suspend lazy -> import('./tables/SdList.coffee').then (m) -> default: m. SdList
export SdTable = suspend lazy -> import('./tables/SdTable.coffee').then (m) -> default: m. SdTable
export SdContentEditor = suspend lazy -> import('./tables/SdContentEditor.coffee').then (m) -> default: m. SdContentEditor
export SdEditor = suspend lazy -> import('./editor/SdEditor.coffee').then (m) -> default: m. SdEditor
export MarkdownDisplay = suspend lazy -> import('./markdown/MarkdownDisplay.coffee').then (m) -> default: m. MarkdownDisplay
export ColorPicker = suspend lazy -> import('./forms/ColorPicker.coffee').then (m) -> default: m. ColorPicker
export ColorPickerField = suspend lazy -> import('./forms/ColorPicker.coffee').then (m) -> default: m. ColorPickerField

export * from './forms/uniforms-custom/select-implementation'
export {LongTextField} from './forms/uniforms-custom/src'
export ManagedForm = suspend lazy -> import('./forms/ManagedForm.coffee').then (m) -> default: m.ManagedForm
export FormModal = suspend lazy -> import('./forms/FormModal.coffee').then (m) -> default: m.FormModal
export LoginForm = suspend lazy -> import('./login-forms/LoginForm.coffee').then (m) -> default: m.LoginForm

export QueryEditor = suspend lazy -> import('./query-editor/QueryEditor.coffee').then (m) -> default: m.QueryEditor
export QueryEditorField = suspend lazy -> import('./query-editor/QueryEditorField.coffee').then (m) -> default: m.QueryEditorField
export SdDocumentSelect = suspend lazy -> import('./tables/SdDocumentSelect.coffee').then (m) -> default: m.SdDocumentSelect
export SdDocumentSelectField = suspend lazy -> import('./tables/SdDocumentSelect.coffee').then (m) -> default: m.SdDocumentSelectField