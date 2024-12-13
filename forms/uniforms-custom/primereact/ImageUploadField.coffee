import React from 'react'
import { FileUpload } from 'primereact/fileupload';
import connectFieldPlus from '../../connectFieldPlus'
import {filterDOMProps} from 'uniforms'
import { Button } from 'primereact/button';

export default connectFieldPlus ({
  name
  disabled
  onChange
  value
  props...
}) ->

  <div>
    <label htmlFor="file-input">
      
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '10px' }}>
        {if Array.isArray(value) and value.length > 0
          value.map (url, index) ->
            <div key={index} style={{ position: 'relative' }}>
              <img
                alt=""
                style={{ cursor: 'pointer', width: '150px', height: '150px', objectFit: 'cover' }}
                src={url}
              />
              <button
                onClick={(e) ->
                  e.preventDefault()
                  e.stopPropagation()
                  onChange value.filter (_, i) -> i != index
                }
                style={{
                  position: 'absolute'
                  top: '5px'
                  right: '5px'
                  background: 'rgba(255,255,255,0.8)'
                  border: 'none'
                  borderRadius: '50%'
                  width: '24px'
                  height: '24px'
                  cursor: 'pointer'
                  display: 'flex'
                  alignItems: 'center'
                  justifyContent: 'center'
                }}
              >
                ×
              </button>
            </div>
        else
          <Button 
            label="Choose your photos"
            onClick={(e) -> 
              e.preventDefault()
              document.getElementById('file-input').click()
            }
          />
        }
      </div>
    </label>
    <input
      accept="image/*"
      multiple
      id="file-input"
      onChange={({target}) -> 
        if target.files?.length
          urls = Array.from(target.files).map (file) -> URL.createObjectURL(file)
          onChange urls
      }
      style={{ display: 'none' }}
      type="file"
    />
  </div>