import {addLocale} from 'primereact/api'
import locales from './locales.json'
import _ from 'lodash'

_(locales).forEach (locale, key) ->
  addLocale key, locale
