import React from 'react'
import {ReactiveVar} from 'meteor/reactive-var'
import {useTracker} from 'meteor/react-meteor-data'
import './addLocales'
import {locale} from 'primereact/api'

export Configurations =
  new ReactiveVar
    test: 'Test! 123 123!'
    files: null

export config = (options) ->
  if options.locale?
    locale options.locale
  Configurations.set {Configurations.get()..., options...}

export useConfig = -> useTracker -> Configurations.get()
