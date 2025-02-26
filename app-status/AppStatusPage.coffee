import {Meteor} from 'meteor/meteor'
import {MarkdownDisplay} from 'meteor/janmp:sdui'
import React from 'react'

appStatus = Meteor.settings.public.appStatus ? {}

export appIsOn = appStatus.isOn

defaultMessage = """
  # 🚧 Die App ist zur Zeit nicht verfügbar 🚧
  Bitte versuchen Sie es später noch einmal.
"""

export AppStatusPage = ->
  <div className='h-full w-full p-2'>
    <MarkdownDisplay markdown={appStatus.message ? defaultMessage} />
  </div>
  
