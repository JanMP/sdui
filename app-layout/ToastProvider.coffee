import {Meteor} from 'meteor/meteor'
import React, {useRef, useContext, createContext} from 'react'
import {Toast} from 'primereact/toast'

ToastContext = createContext null

export useToast = ->
  toastRef = useContext ToastContext
  toastRef.current
  

export ToastProvider = ({children}) ->
  toast = useRef null
  <>
    <Toast ref={toast} />
    <ToastContext.Provider value={toast}>
       {children}
     </ToastContext.Provider>
  </>