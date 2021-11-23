import defaultTwind from 'twind'
import {ReactiveVar} from 'meteor/reactive-var'
import {useTracker} from 'meteor/react-meteor-data'

export Options =
  new ReactiveVar
    twind: defaultTwind

export config = (options) -> Options.set {Options.get()..., options...}

export useConfig = -> useTracker Options.get

export useTw = -> useTracker -> Options.get()?.twind?.tw

