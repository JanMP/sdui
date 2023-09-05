import React from 'react'
import {ReactiveVar} from 'meteor/reactive-var'
import {useTracker} from 'meteor/react-meteor-data'
import './addLocales-primereact'
import {locale} from 'primereact/api'
import i18next from 'i18next'
import {initReactI18next} from 'react-i18next'
import i18nResources from './i18next-resources-sdui.json'

export Configurations =
  new ReactiveVar
    test: 'Test! 123 123!'
    files: null

#TODO: set up to handle changes, this pretty much only a init function so far
export config = (options = {}) ->
  if options.locale?
    locale options.locale
  Configurations.set {Configurations.get()..., options...}
  i18next
  .use initReactI18next
  .init
    lng: unless options.localie is 'de' then options.locale
    resources: options.i18nResources ? i18nResources
    fallbackLng: false
    debug: true


export useConfig = -> useTracker -> Configurations.get()
