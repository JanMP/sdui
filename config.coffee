
import {ReactiveVar} from 'meteor/reactive-var'
import {useTracker} from 'meteor/react-meteor-data'

argsToString = (args...) ->
  args
    .map (x) -> "#{x} "
    .join()

noTwind =
  tw: argsToString
  apply: argsToString

export Options =
  new ReactiveVar
    twind: noTwind

export config = (options) -> Options.set {Options.get()..., options...}

export useConfig = -> useTracker Options.get

export useTw = -> useTracker -> Options.get()?.twind?.tw

