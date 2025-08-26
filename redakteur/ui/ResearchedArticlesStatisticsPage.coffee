import React, {useEffect} from 'react'
import {SdTable} from 'meteor/janmp:sdui'

export createResarchedArticlesStatisticsPage = ({dataOptions}) -> ->
  <SdTable
    dataOptions={dataOptions}
  />