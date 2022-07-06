import React from 'react'
import {ReactiveVar} from 'meteor/reactive-var'
import {useTracker} from 'meteor/react-meteor-data'

export Configurations =
  new ReactiveVar
    test: 'Test! 123 123!'
    files: null

export config = (options) -> Configurations.set {Configurations.get()..., options...}

export useConfig = -> useTracker -> Configurations.get()
