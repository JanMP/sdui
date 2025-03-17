/**
 * Combined TypeScript declarations
 * Generated on Mon Mar  3 11:37:49 CET 2025
 */

declare namespace SduiComponents {

  // ====== From: coffee-compiled/ai/ChatAgent.d.ts ======
  // File: ChatAgent
  {};

  // ====== From: coffee-compiled/ai/ChatAgent.test.d.ts ======
  // File: ChatAgent.test

  // ====== From: coffee-compiled/ai/SdAi.d.ts ======
  // File: SdAi
  const SdAi: any;

  // ====== From: coffee-compiled/ai/TextEmbeddingModel.d.ts ======
  // File: TextEmbeddingModel
  const TextEmbeddingModel: {
      new (settings: object): {
          settings: any;
          create({ context }: {
              context: any;
          }): any;
      };
  };

  // ====== From: coffee-compiled/ai/TextEmbeddingModel.test.d.ts ======
  // File: TextEmbeddingModel.test
  {};

  // ====== From: coffee-compiled/ai/getMultimodalEmbedding.d.ts ======
  // File: getMultimodalEmbedding
  function getMultimodalEmbedding({ content, settings }: {
      content: any;
      settings: any;
  }): Promise<any>;

  // ====== From: coffee-compiled/ai/qdrant/RestClient.d.ts ======
  // File: RestClient
  function createRestClient(settings: any): {
      get: ({ path }: {
          path: any;
      }) => any;
      post: ({ path, data }: {
          path: any;
          data: any;
      }) => any;
      put: ({ path, data }: {
          path: any;
          data: any;
      }) => any;
      delete: ({ path }: {
          path: any;
      }) => any;
      head: ({ path }: {
          path: any;
      }) => any;
  };

  // ====== From: coffee-compiled/ai/qdrant/createQdrantCollection.d.ts ======
  // File: createQdrantCollection
  function _default({ collectionName }: {
      collectionName: any;
  }): {
      drop: () => any;
      recreate: () => any;
      listCollections: () => any;
      info: () => any;
      addPoints: ({ points }: {
          points: any;
      }) => any;
      getPointById: ({ id }: {
          id: any;
      }) => any;
      removePoints: ({ points }: {
          points: any;
      }) => any;
      search: ({ filter, params, vector, limit }: {
          filter: any;
          params: any;
          vector: any;
          limit?: number;
      }) => any;
  };

  // ====== From: coffee-compiled/ai/qdrant/qdrant.d.ts ======
  // File: qdrant
  function createCollection({ collectionName }: {
      collectionName: any;
  }): Promise<any>;
  function deleteCollection({ collectionName }: {
      collectionName: any;
  }): any;
  function listCollections(): any;
  function collectionInfo({ collectionName }: {
      collectionName: any;
  }): any;
  function addPoints({ collectionName, points }: {
      collectionName: any;
      points: any;
  }): any;
  function getPointById({ collectionName, id }: {
      collectionName: any;
      id: any;
  }): any;
  function removePoints({ collectionName, points }: {
      collectionName: any;
      points: any;
  }): any;
  function search({ collectionName, filter, params, vector, limit }: {
      collectionName: any;
      filter: any;
      params: any;
      vector: any;
      limit?: number;
  }): any;

  // ====== From: coffee-compiled/ai/setupChatModel.d.ts ======
  // File: setupChatModel
  function setupChatModel(settings: any): any;

  // ====== From: coffee-compiled/ai/setupOpenAiClient.d.ts ======
  // File: setupOpenAiClient
  function setupOpenAiClient({ settingName }: {
      settingName?: string;
  }): {
      chat: (props: any) => any;
      chatStream: (props: any) => any;
      embeddings: (props: any) => any;
  };

  // ====== From: coffee-compiled/api/createDefaultPipeline.d.ts ======
  // File: createDefaultPipeline
  function createDefaultPipeline({ getPreSelectPipeline, getProcessorPipeline, listSchema }: {
      getPreSelectPipeline: any;
      getProcessorPipeline: any;
      listSchema: any;
  }): {
      defaultGetRowsPipeline: ({ pub, search, query, sort, limit, skip }: {
          pub: any;
          search: any;
          query?: {};
          sort?: {
              _id: number;
          };
          limit?: number;
          skip?: number;
      }) => Promise<any>;
      defaultGetExportPipeline: ({ search, query, sort }: {
          search: any;
          query?: {};
          sort?: {
              _id: number;
          };
      }) => Promise<any[]>;
  };

  // ====== From: coffee-compiled/api/createDefaultPipeline.test.d.ts ======
  // File: createDefaultPipeline.test
  {};

  // ====== From: coffee-compiled/api/createTableDataAPI.d.ts ======
  // File: createTableDataAPI
  /**
  @type {types.createTableDataAPI}
  */
  const createTableDataAPI: types.createTableDataAPI;

  // ====== From: coffee-compiled/api/createTableDataMethods.d.ts ======
  // File: createTableDataMethods
  function createTableDataMethods({ viewTableRole, editRole, addRole, deleteRole, exportTableRole, sourceName, collection, useObjectIds, getRowsPipeline, getExportPipeline, canEdit, canAdd, canDelete, canExport, formSchema, makeFormDataFetchMethodRunFkt, makeSubmitMethodRunFkt, makeDeleteMethodRunFkt, checkDisableDeleteForRow, checkDisableEditForRow, sdai }: {
      viewTableRole: any;
      editRole: any;
      addRole: any;
      deleteRole: any;
      exportTableRole: any;
      sourceName: any;
      collection: any;
      useObjectIds: any;
      getRowsPipeline: any;
      getExportPipeline: any;
      canEdit: any;
      canAdd: any;
      canDelete: any;
      canExport: any;
      formSchema: any;
      makeFormDataFetchMethodRunFkt: any;
      makeSubmitMethodRunFkt: any;
      makeDeleteMethodRunFkt: any;
      checkDisableDeleteForRow: any;
      checkDisableEditForRow: any;
      sdai: any;
  }): {
      getRows: any;
  };

  // ====== From: coffee-compiled/api/createUserManagementAPI.d.ts ======
  // File: createUserManagementAPI
  function createUserManagementAPI({ sourceName, path, apiKey, roleScope, adminRole, initialUserRole, switchableRoles }: {
      sourceName: any;
      path: any;
      apiKey: any;
      roleScope: any;
      adminRole: any;
      initialUserRole: any;
      switchableRoles: any;
  }): any;

  // ====== From: coffee-compiled/api/publishTableData.d.ts ======
  // File: publishTableData
  function publishTableData({ viewTableRole, sourceName, collection, getRowsPipeline, noAutomaticObserver, debounceDelay, getObservers }: {
      viewTableRole: any;
      sourceName: any;
      collection: any;
      getRowsPipeline: any;
      noAutomaticObserver?: boolean;
      debounceDelay?: number;
      getObservers: any;
  }): any;

  // ====== From: coffee-compiled/app-layout/AppToolbar.d.ts ======
  // File: AppToolbar
  function AppToolbar({ toolbarStart, isMobile, onToggleSidebar }: {
      toolbarStart: any;
      isMobile: any;
      onToggleSidebar: any;
  }): any;

  // ====== From: coffee-compiled/app-layout/LoginPage.d.ts ======
  // File: LoginPage
  function LoginPage(): any;

  // ====== From: coffee-compiled/app-layout/PathNotFound.d.ts ======
  // File: PathNotFound
  function PathNotFound(): any;

  // ====== From: coffee-compiled/app-layout/ResetPasswordPage.d.ts ======
  // File: ResetPasswordPage
  function ResetPasswordPage(): any;

  // ====== From: coffee-compiled/app-layout/RoleGuard.d.ts ======
  // File: RoleGuard
  function AccessDeniedPage(): any;
  function RoleGuard({ role }: {
      role: any;
  }): any;

  // ====== From: coffee-compiled/app-layout/SdAppLayout.d.ts ======
  // File: SdAppLayout
  function SdAppLayout({ dataOptions }: {
      dataOptions: any;
  }): any;

  // ====== From: coffee-compiled/app-layout/ToastProvider.d.ts ======
  // File: ToastProvider
  function useToast(): any;
  function ToastProvider({ children }: {
      children: any;
  }): any;

  // ====== From: coffee-compiled/app-layout/VerifyEmailPage.d.ts ======
  // File: VerifyEmailPage
  function VerifyEmailPage(): any;

  // ====== From: coffee-compiled/app-layout/createAppLayoutAPI.d.ts ======
  // File: createAppLayoutAPI
  function createAppLayoutAPI({ sourceName, sourceArray, toolbarStart, routerLess }: {
      sourceName: string;
      sourceArray: [any];
      toolbarStart: Function;
  }): any;

  // ====== From: coffee-compiled/app-status/AppStatusPage.d.ts ======
  // File: AppStatusPage
  const appIsOn: any;
  function AppStatusPage(): any;

  // ====== From: coffee-compiled/chat/DefaultMessage.d.ts ======
  // File: DefaultMessage
  function DefaultMessage({ message, hasPdfButton, onChangeFeedback, showTools }: {
      message: any;
      hasPdfButton?: boolean;
      onChangeFeedback: any;
      showTools?: boolean;
  }): any;

  // ====== From: coffee-compiled/chat/DefaultMetaDataDisplay.d.ts ======
  // File: DefaultMetaDataDisplay
  function DefaultMetaDataDisplay({ metaData, linkedItems }: {
      metaData: any;
      linkedItems: any;
  }): any;

  // ====== From: coffee-compiled/chat/SdChat.d.ts ======
  // File: SdChat
  function SdChat({ dataOptions, className, customComponents, processMessageText, showTools }: {
      dataOptions: any;
      className?: string;
      customComponents?: {};
      processMessageText: any;
      showTools?: boolean;
  }): any;

  // ====== From: coffee-compiled/chat/SdChatLog.d.ts ======
  // File: SdChatLog
  function SdChatLog({ dataOptions }: {
      dataOptions: any;
  }): any;

  // ====== From: coffee-compiled/chat/SessionListHeader.d.ts ======
  // File: SessionListHeader
  function SessionListHeader({ onAdd }: {
      onAdd: any;
  }): any;

  // ====== From: coffee-compiled/chat/SessionListItemContent.d.ts ======
  // File: SessionListItemContent
  function SessionListItemContent({ rowData }: {
      rowData: any;
  }): any;

  // ====== From: coffee-compiled/chat/createChatAPI.d.ts ======
  // File: createChatAPI
  const chatSchema: any;
  const chatMetaDataSchema: any;
  function createChatAPI({ sourceName, messageCollection, sessionListCollection, metaDataCollection, usageLimitCollection, isSingleSessionChat, viewChatRole, addSessionRole, bots, reactToNewMessage, onNewSession, messagesLimit, getUsageLimits }: {
      sourceName: string;
      messageCollection: Mongo.Collection;
      sessionListCollection: Mongo.Collection;
      metaDataCollection?: Mongo.Collection;
      usageLimitCollection?: Mongo.Collection;
      isSingleSessionChat?: boolean;
      viewChatRole?: any;
      addSessionRole?: any;
      bots?: any[];
      reactToNewMessage?: Function;
      getUsageLimits?: () => {
          maxMessagesPerDay?: number;
          maxSessionsPerDay?: number;
          maxMessagesPerSession?: number;
          maxMessageLength?: number;
      } | void;
      onNewSession?: Function;
      messagesLimit?: number;
  }): any;

  // ====== From: coffee-compiled/chat/createChatBot.d.ts ======
  // File: createChatBot
  function createChatBot({ chatClient, getSystemPrompt, getTools, messageCollection, botUserData }: {
      chatClient: any;
      getSystemPrompt?: string;
      getTools?: Function;
      messageCollection: Mongo.Collection;
      botUserData?: any;
  }): {
      call: ({ sessionId, messageStubId, context }: {
          sessionId: any;
          messageStubId: any;
          context: any;
      }) => any;
      createMessageStub: ({ sessionId, text, followMessageId, followDelay }: {
          sessionId: any;
          text?: string;
          followMessageId?: any;
          followDelay?: number;
      }) => Promise<any>;
      updateMessageStub: ({ messageStubId, text, tools }: {
          messageStubId: string;
          text?: string;
          tools?: any;
      }) => Promise<void>;
      finalizeMessageStub: ({ messageStubId, text, tools, usage }: {
          messageStubId: any;
          text: any;
          tools: any;
          usage: any;
      }) => any;
      buildContext: ({ sessionId, history, limit }: {
          sessionId: any;
          history?: any;
          limit?: number;
      }) => Promise<any[]>;
  };

  // ====== From: coffee-compiled/chat/createChatLogAPI.d.ts ======
  // File: createChatLogAPI
  const addCostsPipeline: ({
      $lookup: {
          from: string;
          localField: string;
          foreignField: string;
          as: string;
      };
      $addFields?: undefined;
      $fill?: undefined;
  } | {
      $addFields: {
          costsForModel: {
              $arrayElemAt: (string | number)[];
          };
          costInUSD?: undefined;
      };
      $lookup?: undefined;
      $fill?: undefined;
  } | {
      $fill: {
          output: {
              usage: {
                  value: {
                      prompt: number;
                      completion: number;
                  };
              };
              costsForModel: {
                  value: {
                      prompt: number;
                      completion: number;
                  };
              };
          };
      };
      $lookup?: undefined;
      $addFields?: undefined;
  } | {
      $addFields: {
          costInUSD: {
              $sum: {
                  $add: {
                      $multiply: string[];
                  }[];
              };
          };
          costsForModel?: undefined;
      };
      $lookup?: undefined;
      $fill?: undefined;
  })[];
  function createChatLogAPI({ sourceName, messageCollection, viewTableRole }: {
      sourceName: any;
      messageCollection: any;
      viewTableRole: any;
  }): any;

  // ====== From: coffee-compiled/chat/createChatMethods.d.ts ======
  // File: createChatMethods
  function createChatMethods({ sourceName, messageCollection, sessionListCollection, metaDataCollection, isSingleSessionChat, viewChatRole, addSessionRole, reactToNewMessage, onNewSession, getUsageLimits }: {
      sourceName: string;
      messageCollection: Mongo.Collection;
      sessionListCollection: Mongo.Collection;
      metaDataCollection?: Mongo.Collection;
      isSingleSessionChat?: boolean;
      viewChatRole?: string;
      addSessionRole?: string;
      reactToNewMessage?: Function;
      onNewSession?: Function;
      getUsageLimits?: Function;
  }): any;

  // ====== From: coffee-compiled/chat/createChatPublications.d.ts ======
  // File: createChatPublications
  function createChatPublications({ sourceName, messageCollection, sessionListCollection, metaDataCollection, isSingleSessionChat, viewChatRole, getUsageLimits, messagesLimit }: {
      sourceName: string;
      messageCollection: Mongo.Collection;
      sessionListCollection: Mongo.Collection;
      metaDataCollection?: Mongo.Collection;
      isSingleSessionChat?: boolean;
      viewChatRole?: string;
      getUsageLimits?: Function;
      messagesLimit?: number;
  }): any;

  // ====== From: coffee-compiled/chat/createChatSessionListAPI.d.ts ======
  // File: createChatSessionListAPI
  function createChatSessionListAPI({ sourceName, sessionListCollection, viewChatRole, addSessionRole }: {
      sourceName: string;
      sessionListCollection: Mongo.Collection;
      viewChatRole: string;
      addSessionRole: string;
  }): any;

  // ====== From: coffee-compiled/common/ErrorBoundary.d.ts ======
  // File: ErrorBoundary
  const ErrorBoundary: {
      new (props: any): {
          state: {
              hasError: boolean;
              msg: string;
          };
          componentDidCatch(error: any, info: any): void;
          resetEditor(): any;
          render(): any;
      };
  };

  // ====== From: coffee-compiled/common/downloadAsFile.d.ts ======
  // File: downloadAsFile
  function downloadAsFile({ dataString, mimeType, fileName }: {
      dataString: any;
      mimeType: any;
      fileName: any;
  }): void;

  // ====== From: coffee-compiled/common/generateUUID.d.ts ======
  // File: generateUUID
  function generateUUID(): string;

  // ====== From: coffee-compiled/common/getColumnsToExport.d.ts ======
  // File: getColumnsToExport
  function getColumnsToExport({ schema }: {
      schema: any;
  }): any;

  // ====== From: coffee-compiled/common/meteorApply.d.ts ======
  // File: meteorApply
  /**
  A wrapper around Meteor.apply to make it thenable
  @type {(options: {method: string, data?: any, options?: Object}) => Promise}
  */
  const meteorApply: (options: {
      method: string;
      data?: any;
      options?: any;
  }) => Promise<any>;

  // ====== From: coffee-compiled/common/processSearchInput.d.ts ======
  // File: processSearchInput
  function _default(inputString: any): {
      isValidRegEx: boolean;
      warn: boolean;
      flags: any;
      processedString: any;
  };

  // ====== From: coffee-compiled/common/roleChecks.d.ts ======
  // File: roleChecks
  function userWithIdIsInRole({ role, id }: {
      role: any;
      id: any;
  }): any;
  function currentUserIsInRole(role: any): boolean;
  function useCurrentUserIsInRole(role: any): boolean;
  function currentUserMustBeInRole(role: any): Promise<void>;
  function scopesForUserWithIdInRole({ role, id }: {
      role: any;
      id: any;
  }): any;
  function scopesForCurrentUserInRole(role: string | Array<string>): any[];
  function useScopesForCurrentUserInRole(role: string | Array<string>): any[];
  type Role = any;

  // ====== From: coffee-compiled/common/runTransaction.d.ts ======
  // File: runTransaction
  function runTransaction(fn: any): Promise<any>;

  // ====== From: coffee-compiled/common/toStringWithUnitPrefix.d.ts ======
  // File: toStringWithUnitPrefix
  function _default(n: any, options: any): string;

  // ====== From: coffee-compiled/common/useSession.d.ts ======
  // File: useSession
  function useSession(key: any, intitialValue: any): any[];

  // ====== From: coffee-compiled/config/addLocales-primereact.d.ts ======
  // File: addLocales-primereact
  {};

  // ====== From: coffee-compiled/config/config.d.ts ======
  // File: config
  const Configurations: any;
  function config(options?: {}): any;
  function useConfig(): any;

  // ====== From: coffee-compiled/editor/SdEditor.d.ts ======
  // File: SdEditor
  /**
  @type {({value, onChange, editorWidth, editorHeight, mode, theme, Header} : {value: string, onChange: (newValue: string) => void, editorWidth?: string, editorHeight?: string, mode?: string, theme?: string, Header?: React.FC})  => React.FC}
  */
  const SdEditor: ({ value, onChange, editorWidth, editorHeight, mode, theme, Header }: {
      value: string;
      onChange: (newValue: string) => void;
      editorWidth?: string;
      editorHeight?: string;
      mode?: string;
      theme?: string;
      Header?: React.FC;
  }) => React.FC;

  // ====== From: coffee-compiled/forms/ActionButton.d.ts ======
  // File: ActionButton
  function ActionButton({ method, data, options, onAction, customTemplate, label, icon, onSuccess, successMsg, onError, errorMsg, confirmation, className, disabled, buttonProps }: {
      method: string | null;
      data: any | null;
      options: any | null;
      onAction?: () => void;
      label: string | null;
      icon: string | null;
      customTemplate: React.Component;
      onSuccess?: (result: any) => void;
      successMsg: string | null;
      onError?: (error: Error) => void;
      errorMsg: string | null;
      confirmation: string | null;
      className: string | null;
      disabled: boolean | null;
      buttonProps: any | null;
  }): any;

  // ====== From: coffee-compiled/forms/ColorPicker.d.ts ======
  // File: ColorPicker
  function ColorPicker({ disabled, fieldType, id, inputRef, label, name, onChange, readOnly, required, value, ...props }: {
      [x: string]: any;
      disabled: any;
      fieldType: any;
      id: any;
      inputRef: any;
      label: any;
      name: any;
      onChange: any;
      readOnly: any;
      required: any;
      value: any;
  }): any;
  const ColorPickerField: any;

  // ====== From: coffee-compiled/forms/ConfirmationModal.d.ts ======
  // File: ConfirmationModal
  function ConfirmationModal({ text, onConfirm, onCancel, isOpen, setIsOpen }: {
      text: string;
      onConfirm?: () => void;
      onCancel?: () => void;
      isOpen: boolean;
      setIsOpen: (newValue: boolean) => void;
  }): any;

  // ====== From: coffee-compiled/forms/DynamicField.d.ts ======
  // File: DynamicField
  function DynamicField({ schemaBridge, fieldName, label, value, onChange, validate, mayEdit, className }: {
      schemaBridge: any;
      fieldName: any;
      label: any;
      value: any;
      onChange: any;
      validate: any;
      mayEdit?: boolean;
      className: any;
  }): any;

  // ====== From: coffee-compiled/forms/FeedbackButtonField.d.ts ======
  // File: FeedbackButtonField
  function FeedbackButton({ value, onChange }: {
      value: any;
      onChange: any;
  }): any;
  const FeedbackButtonField: any;
  function FeedbackButtonTableField({ row, columnKey, schemaBridge, onChangeField, measure, mayEdit }: {
      row: any;
      columnKey: any;
      schemaBridge: any;
      onChangeField: any;
      measure: any;
      mayEdit: any;
  }): any;

  // ====== From: coffee-compiled/forms/FormModal.d.ts ======
  // File: FormModal
  function FormModal({ schemaBridge, onSubmit, model, isOpen, onRequestClose, header, children, disabled, readOnly, onChangeModel }: {
      schemaBridge: any;
      onSubmit: any;
      model: any;
      isOpen: any;
      onRequestClose: any;
      header: any;
      children: any;
      disabled?: boolean;
      readOnly: any;
      onChangeModel: any;
  }): any;

  // ====== From: coffee-compiled/forms/GravatarField.d.ts ======
  // File: GravatarField
  function Gravatar(props: any): any;
  const GravatarField: any;

  // ====== From: coffee-compiled/forms/LinkField.d.ts ======
  // File: LinkField
  const LinkField: any;
  function LinkTableField({ row, columnKey, schemaBridge, onChangeField, measure, mayEdit }: {
      row: any;
      columnKey: any;
      schemaBridge: any;
      onChangeField: any;
      measure: any;
      mayEdit: any;
  }): any;

  // ====== From: coffee-compiled/forms/ManagedForm.d.ts ======
  // File: ManagedForm
  function ManagedForm({ schemaBridge, model, onChangeModel, onSubmit, disabled, children, actionLabel, showResetButton, allowUnchangedSubmit }: {
      schemaBridge: any;
      model: any;
      onChangeModel: any;
      onSubmit: any;
      disabled: any;
      children: any;
      actionLabel?: string;
      showResetButton?: boolean;
      allowUnchangedSubmit?: boolean;
  }): any;

  // ====== From: coffee-compiled/forms/RatingField.d.ts ======
  // File: RatingField
  const RatingField: any;

  // ====== From: coffee-compiled/forms/ThumbsField.d.ts ======
  // File: ThumbsField
  function Thumbs({ value, onChange, fontSize }: {
      value: any;
      onChange: any;
      fontSize?: string;
  }): any;
  const ThumbsField: any;
  function ThumbsTableField({ row, columnKey, schemaBridge, onChangeField, measure, mayEdit }: {
      row: any;
      columnKey: any;
      schemaBridge: any;
      onChangeField: any;
      measure: any;
      mayEdit: any;
  }): any;

  // ====== From: coffee-compiled/forms/connectFieldPlus.d.ts ======
  // File: connectFieldPlus
  declare function _default(Component: any): any;
  _default;

  // ====== From: coffee-compiled/forms/connectFieldWithLabel.d.ts ======
  // File: connectFieldWithLabel
  declare function _default(Component: any): any;
  _default;

  // ====== From: coffee-compiled/forms/uniforms-custom/primereact/AutoField.d.ts ======
  // File: AutoField
  declare const _default: any;
  _default;

  // ====== From: coffee-compiled/forms/uniforms-custom/primereact/BoolField.d.ts ======
  // File: BoolField
  declare const _default: any;
  _default;

  // ====== From: coffee-compiled/forms/uniforms-custom/primereact/DateField.d.ts ======
  // File: DateField
  declare const _default: any;
  _default;

  // ====== From: coffee-compiled/forms/uniforms-custom/primereact/ImageUploadField.d.ts ======
  // File: ImageUploadField
  declare const _default: any;
  _default;

  // ====== From: coffee-compiled/forms/uniforms-custom/primereact/LongTextField.d.ts ======
  // File: LongTextField
  declare const _default: any;
  _default;

  // ====== From: coffee-compiled/forms/uniforms-custom/primereact/MultiSelectField.d.ts ======
  // File: MultiSelectField
  declare const _default: any;
  _default;

  // ====== From: coffee-compiled/forms/uniforms-custom/primereact/NumField.d.ts ======
  // File: NumField
  declare const _default: any;
  _default;

  // ====== From: coffee-compiled/forms/uniforms-custom/primereact/PasswordField.d.ts ======
  // File: PasswordField
  declare const _default: any;
  _default;

  // ====== From: coffee-compiled/forms/uniforms-custom/primereact/RadioField.d.ts ======
  // File: RadioField
  declare const _default: any;
  _default;

  // ====== From: coffee-compiled/forms/uniforms-custom/primereact/SelectField.d.ts ======
  // File: SelectField
  declare const _default: any;
  _default;

  // ====== From: coffee-compiled/forms/uniforms-custom/primereact/TextField.d.ts ======
  // File: TextField
  declare const _default: any;
  _default;

  // ====== From: coffee-compiled/jobstable/SdJobsTable.d.ts ======
  // File: SdJobsTable
  function SdJobsTable({ dataOptions }: {
      dataOptions: any;
  }): any;

  // ====== From: coffee-compiled/jobstable/createJobsTableDataAPI.d.ts ======
  // File: createJobsTableDataAPI
  function createJobsTableDataAPI(): any;

  // ====== From: coffee-compiled/login-forms/EmailVerification.d.ts ======
  // File: EmailVerification
  function EmailVerification(): any;

  // ====== From: coffee-compiled/login-forms/LoginButton.d.ts ======
  // File: LoginButton
  function LoginButton({ onLoginClick, onUserClick }: {
      onLoginClick: any;
      onUserClick: any;
  }): any;

  // ====== From: coffee-compiled/login-forms/LoginForm.d.ts ======
  // File: LoginForm
  function LoginForm({ allowResetPassword }: {
      allowResetPassword?: boolean;
  }): any;

  // ====== From: coffee-compiled/login-forms/SetPasswordForm.d.ts ======
  // File: SetPasswordForm
  function SetPasswordForm({ token }: {
      token: any;
  }): any;

  // ====== From: coffee-compiled/markdown/MarkdownDisplay.d.ts ======
  // File: MarkdownDisplay
  function MarkdownDisplay({ markdown, contentClass, markdownItInstance }: {
      markdown?: string;
      contentClass: any;
      markdownItInstance?: any;
  }): any;

  // ====== From: coffee-compiled/misc-components/FormattedJSON.d.ts ======
  // File: FormattedJSON
  function FormattedJSON({ data }: {
      data: any;
  }): any;

  // ====== From: coffee-compiled/qa-articles/createQAArticlesAPI.d.ts ======
  // File: createQAArticlesAPI
  function createQAArticlesAPI({ sourceName, collection, viewTableRole, editRole, getEmbedding }: {
      sourceName: string;
      collection: Mongo.Collection;
      viewTableRole: string;
      editRole: string;
      getEmbedding: Function;
  }): any;

  // ====== From: coffee-compiled/runTests.d.ts ======
  // File: runTests
  function runTests(): any;

  // ====== From: coffee-compiled/schema/Schema.d.ts ======
  // File: Schema
  const Schema: {
      new (_schema: any, options: any): {
          _schema: any;
          options: any;
          ajv: any;
          modelValidator: any;
          validate: any;
          validator: (model: any) => {
              details: any;
          };
          methodValidator: (model: any) => void;
          bridge: any;
          firstLevelSchemaKeys: any;
          addProperty(property: any): any;
          withId(): any;
          pick(keys: any): any;
          omit(keys: any): any;
          getQuickTypeForKey(key: any): "string" | "stringArray" | "number" | "numberArray" | "unhandled";
      };
  };

  // ====== From: coffee-compiled/sdui-client-dynamic.d.ts ======
  // File: sdui-client-dynamic
  function ActionButton(props: any): any;
  function SdList(props: any): any;
  function SdTable(props: any): any;
  function DateDisplayTableComponent(props: any): any;
  function SdContentEditor(props: any): any;
  function SdEditor(props: any): any;
  function MarkdownDisplay(props: any): any;
  function ColorPicker(props: any): any;
  function ColorPickerField(props: any): any;
  function RatingField(props: any): any;
  function Thumbs(props: any): any;
  function ThumbsField(props: any): any;
  function ThumbsTableField(props: any): any;
  function LinkField(props: any): any;
  function LinkTableField(props: any): any;
  function ManagedForm(props: any): any;
  function FormModal(props: any): any;
  function LoginForm(props: any): any;
  function LoginButton(props: any): any;
  function FeedbackButton(props: any): any;
  function FeedbackButtonField(props: any): any;
  function FeedbackButtonTableField(props: any): any;
  function SdDocumentSelect(props: any): any;
  function SdDocumentSelectField(props: any): any;
  function SdChat(props: any): any;
  function SdChatLog(props: any): any;
  function SdAppLayout(props: any): any;
  function Gravatar(props: any): any;
  function GravatarField(props: any): any;
  function FormattedJSON(props: any): any;
  function SdUserTable(props: any): any;
  function SdJobsTable(props: any): any;

  // ====== From: coffee-compiled/sdui-client.d.ts ======
  // File: sdui-client
  {};

  // ====== From: coffee-compiled/sdui-server.d.ts ======
  // File: sdui-server
  { default as createQdrantCollection } from "./ai/qdrant/createQdrantCollection";

  // ====== From: coffee-compiled/tables/AutoTableAutoField.d.ts ======
  // File: AutoTableAutoField
  function AutoTableAutoField({ row, columnKey, schemaBridge, onChangeField, measure, mayEdit }: {
      row: any;
      columnKey: any;
      schemaBridge: any;
      onChangeField: any;
      measure: any;
      mayEdit: any;
  }): any;

  // ====== From: coffee-compiled/tables/ContentEditor.d.ts ======
  // File: ContentEditor
  function ContentEditor({ tableOptions, displaySingleItemId }: {
      tableOptions: any;
      displaySingleItemId?: string;
  }): any;

  // ====== From: coffee-compiled/tables/DataList.d.ts ======
  // File: DataList
  function DataList({ sourceName, listSchema, rows, limit, loadMoreRows, canSort, sortColumn, sortDirection, onChangeSort, canSearch, search, onChangeSearch, isLoading, canAdd, mayAdd, onAdd, canDelete, mayDelete, onDelete, canEdit, mayEdit, onChangeField, onRowClick, canExport, mayExport, onExportTable, overscanRowCount, customComponents, selectedRowId }: {
      sourceName: any;
      listSchema: any;
      rows: any;
      limit: any;
      loadMoreRows?: (...args: any[]) => void;
      canSort: any;
      sortColumn: any;
      sortDirection: any;
      onChangeSort?: (...args: any[]) => void;
      canSearch: any;
      search: any;
      onChangeSearch?: (...args: any[]) => void;
      isLoading: any;
      canAdd: any;
      mayAdd: any;
      onAdd?: (...args: any[]) => void;
      canDelete: any;
      mayDelete: any;
      onDelete?: (...args: any[]) => void;
      canEdit: any;
      mayEdit: any;
      onChangeField?: (...args: any[]) => void;
      onRowClick: any;
      canExport: any;
      mayExport: any;
      onExportTable?: (...args: any[]) => void;
      overscanRowCount?: number;
      customComponents?: {};
      selectedRowId?: any;
  }): any;

  // ====== From: coffee-compiled/tables/DataTable.d.ts ======
  // File: DataTable
  function DataTable({ sourceName, listSchema, rows, limit, loadMoreRows, canSort, sortColumn, sortDirection, onChangeSort, canSearch, search, onChangeSearch, isLoading, canAdd, mayAdd, onAdd, canDelete, mayDelete, onDelete, canEdit, mayEdit, onChangeField, onRowClick, canExport, onExportTable, mayExport, overscanRowCount, customComponents }: {
      sourceName: any;
      listSchema: any;
      rows: any;
      limit: any;
      loadMoreRows?: (...args: any[]) => void;
      canSort: any;
      sortColumn: any;
      sortDirection: any;
      onChangeSort?: (...args: any[]) => void;
      canSearch: any;
      search: any;
      onChangeSearch?: (...args: any[]) => void;
      isLoading: any;
      canAdd: any;
      mayAdd: any;
      onAdd?: (...args: any[]) => void;
      canDelete: any;
      mayDelete: any;
      onDelete?: (...args: any[]) => void;
      canEdit: any;
      mayEdit: any;
      onChangeField?: (...args: any[]) => void;
      onRowClick: any;
      canExport: any;
      onExportTable?: (...args: any[]) => void;
      mayExport: any;
      overscanRowCount?: number;
      customComponents?: {};
  }): any;

  // ====== From: coffee-compiled/tables/DateDisplayTableComponent.d.ts ======
  // File: DateDisplayTableComponent
  function DateDisplayTableComponentWithNullString(nullString: any): ({ row, columnKey, schemaBridge, onChangeField, mayEdit }: {
      row: any;
      columnKey: any;
      schemaBridge: any;
      onChangeField: any;
      mayEdit: any;
  }) => any;
  function DateDisplayTableComponent({ row, columnKey, schemaBridge, onChangeField, mayEdit }: {
      row: any;
      columnKey: any;
      schemaBridge: any;
      onChangeField: any;
      mayEdit: any;
  }): any;

  // ====== From: coffee-compiled/tables/DefaultHeader.d.ts ======
  // File: DefaultHeader
  /**
  @type {types.DefaultHeader}
  */
  const DefaultHeader: types.DefaultHeader;

  // ====== From: coffee-compiled/tables/DefaultListItem.d.ts ======
  // File: DefaultListItem
  function DefaultListItem({ rowData, index, canDelete, mayDelete, onDelete, onClick, ListItemContent, selectedRowId, measure }: {
      rowData: any;
      index: any;
      canDelete: any;
      mayDelete: any;
      onDelete: any;
      onClick: any;
      ListItemContent?: any;
      selectedRowId: any;
      measure: any;
  }): any;

  // ====== From: coffee-compiled/tables/DynamicTableField.d.ts ======
  // File: DynamicTableField
  /**
  @type {({row, columnKey, schemaBridge, onChangeField, mayEdit}:{row: object, columnKey: string, schemaBridge: any, onChangeField: function, mayEdit: boolean}) =>}
  */
  const DynamicTableField: ({ row, columnKey, schemaBridge, onChangeField, mayEdit }: {
      row: object;
      columnKey: string;
      schemaBridge: any;
      onChangeField: Function;
      mayEdit: boolean;
  }) => any;

  // ====== From: coffee-compiled/tables/MeteorTableDataHandler.d.ts ======
  // File: MeteorTableDataHandler
  /**
  @type {types.MeteorTableDataHandler}
  */
  const MeteorTableDataHandler: types.MeteorTableDataHandler;

  // ====== From: coffee-compiled/tables/SdContentEditor.d.ts ======
  // File: SdContentEditor
  function SdContentEditor({ dataOptions, customComponents }: {
      dataOptions: any;
      customComponents?: {};
  }): any;

  // ====== From: coffee-compiled/tables/SdDocumentSelect.d.ts ======
  // File: SdDocumentSelect
  function SdDocumentSelect({ value, onChange, dataOptions, selectOptions }: {
      value: any;
      onChange: any;
      dataOptions: any;
      selectOptions: any;
  }): any;
  const SdDocumentSelectField: any;

  // ====== From: coffee-compiled/tables/SdList.d.ts ======
  // File: SdList
  function DisplayComponent(tableOptions: any): any;
  function SdList({ dataOptions, customComponents }: {
      dataOptions: any;
      customComponents: any;
  }): any;

  // ====== From: coffee-compiled/tables/SdTable.d.ts ======
  // File: SdTable
  /**
  @type {({dataOptions, customComponents}: {dataOptions: DataTableOptions, customComponents: any}) => React.FC }
  */
  const SdTable: ({ dataOptions, customComponents }: {
      dataOptions: any;
      customComponents: any;
  }) => React.FC;
  type DataTableOptions = any;

  // ====== From: coffee-compiled/tables/SearchInput.d.ts ======
  // File: SearchInput
  function SearchInput({ value, onChange, className }: {
      value: any;
      onChange: any;
      className?: string;
  }): any;

  // ====== From: coffee-compiled/tables/SortSelect.d.ts ======
  // File: SortSelect
  function SortSelect({ listSchema, sortColumn, sortDirection, onChangeSort }: {
      listSchema: any;
      sortColumn: any;
      sortDirection: any;
      onChangeSort: any;
  }): any;

  // ====== From: coffee-compiled/tables/TableEditModalHandler.d.ts ======
  // File: TableEditModalHandler
  /**
  @typedef {import("../interfaces").DataTableDisplayOptions} DataTableDisplayOptions
  */
  /**
  @type {
    (options: {
      tableOptions: DataTableDisplayOptions
      DisplayComponent: {(options: DataTableDisplayOptions): React.FC}
    }) => React.FC

  */
  const TableEditModalHandler: (options: {
      tableOptions: any;
      DisplayComponent: (options: any) => React.FC;
  }) => React.FC;
  type DataTableDisplayOptions = any;

  // ====== From: coffee-compiled/usertable/AllowedRolesContext.d.ts ======
  // File: AllowedRolesContext
  const AllowedRolesContext: any;

  // ====== From: coffee-compiled/usertable/RoleSelect.d.ts ======
  // File: RoleSelect
  const RoleSelectField: any;

  // ====== From: coffee-compiled/usertable/RoleSelectReactive.d.ts ======
  // File: RoleSelectReactive
  function RoleSelectReactive({ row, columnKey, schemaBridge, onChangeField, measure, mayEdit }: {
      row: any;
      columnKey: string;
      schemaBridge: any;
      onChangeField: Function;
      measure: Function;
      mayEdit: boolean;
  }): React.Element;

  // ====== From: coffee-compiled/usertable/RolesDisplay.d.ts ======
  // File: RolesDisplay
  function RolesDisplay({ row, measure }: {
      row: any;
      measure: any;
  }): any;

  // ====== From: coffee-compiled/usertable/SdUserTable.d.ts ======
  // File: SdUserTable
  function SdUserTable({ dataOptions }: {
      dataOptions: any;
  }): any;

  // ====== From: coffee-compiled/usertable/createUserTableAPI.d.ts ======
  // File: createUserTableAPI
  function createUserTableAPI({ userProfileSchema, getAllowedRoles, viewUserTableRole, editUserRole }: {
      userProfileSchema: SimpleSchema;
      getAllowedRoles: Function;
      viewUserTableRole: string;
      editUserRole: string;
  }): any;

}
