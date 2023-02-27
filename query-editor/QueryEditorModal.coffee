import React, {useState} from 'react'
import {QueryEditor} from './QueryEditor.coffee'
import {Dialog} from 'primereact/dialog'

###*
  @param {Object} args
  @param {object} args.bridge
  @param {object} args.rule
  @param {(newValue: object) => void} args.onChangeRule
  @param {boolean} args.useQuery
  @param {(newValue: boolean) => void} args.setUseQuery
  @param {boolean} args.isOpen
  @param {(newValue : boolean) => void} args.setIsOpen
  @return void
  ###
export QueryEditorModal = ({bridge, rule, onChangeRule, isOpen, setIsOpen}) ->


  <Dialog
    visible={isOpen}
    onHide={-> setIsOpen false}
  >
    <QueryEditor
      bridge={bridge}
      rule={rule}
      onChange={onChangeRule}
    />
  </Dialog>