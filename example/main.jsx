import React from 'react'
import ReactDOM from 'react-dom'
import {ReactDOMDagre} from '../lib/es6_global/src/RendererTest.bs'
import './index.css'
import App from './App'

//ReactDOM.render(
ReactDOMDagre.render(
  <React.StrictMode>
    <App/>
  </React.StrictMode>,
  document.getElementById('root')
)
