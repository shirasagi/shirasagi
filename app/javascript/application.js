import "./application.scss"
import Initializer from "./ss/initializer"
import moment from "moment/moment"

Initializer.load(require.context("./initializers", true, /\.js$/i))
Initializer.ready(() => {
  SS.doneReady()
})

if (SS.readyTimeout) {
  clearTimeout(SS.readyTimeout)
  SS.readyTimeout = null
}

window.moment = moment
