import React from 'react'
import {Meteor} from 'meteor/meteor'
import connectFieldPlus from './connectFieldPlus.coffee'
import {Avatar} from 'primereact/Avatar'
import gravatar from 'gravatar.js'
import _ from 'lodash'

###*
  Wrapper around primereact/Avatar that adds
  email and defaultIcon as props and uses gravatar.js
  passes all other props unchanged to Avatar
  ###
export Gravatar = (props) ->

  {email, defaultIcon} = props

  url = gravatar.url email,
    size: 200
    defaultIcon: defaultIcon ? 'identicon'

  avatarProps = _(props).omit('email', 'defaultIcon').merge(image: url).value()
  
  <Avatar {avatarProps...}/>

export GravatarField = connectFieldPlus Gravatar, kind: 'leaf'