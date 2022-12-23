import moment from "moment/moment"
import * as Turbo from "@hotwired/turbo"
import "./application.scss"
import Initializer from "./ss/initializer"

window.moment = moment

Turbo.session.drive = false

Initializer.load(require.context("./initializers", true, /\.js$/i))
Initializer.ready(() => {
  SS.doneReady()
})

if (SS.readyTimeout) {
  clearTimeout(SS.readyTimeout)
  SS.readyTimeout = null
}
