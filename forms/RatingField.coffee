import React from 'react'
import {Rating} from 'primereact/rating'
import connectFieldWithLabel from './connectFieldWithLabel'

export RatingField = connectFieldWithLabel ({label, value, onChange, disabled, props...}) ->
  <Rating
    value={value}
    onChange={(e) -> onChange e.value}
    disabled={disabled}
    {props...}
  />