import moment from "moment/moment"
import * as Turbo from "@hotwired/turbo"
import "./application.scss"
import Initializer from "./ss/initializer"
import TurboFullRedirect from "./ss/turbo_full_redirect"

window.moment = moment

Turbo.session.drive = false

Initializer.load(require.context("./initializers", true, /\.js$/i))
Initializer.ready(() => {
  SS.doneReady()
  TurboFullRedirect.start()
})
