import React from 'react'
import {Rating} from 'primereact/rating'
import connectFielPlus from './connectFielPlus'

export RatingField = connectFielPlus ({label, value, onChange, disabled, props...}) ->
  <Rating
    value={value}
    onChange={(e) -> onChange e.value}
    disabled={disabled}
    {props...}
  />