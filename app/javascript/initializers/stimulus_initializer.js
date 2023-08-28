import Initializer from "../ss/initializer"
import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"

export default class extends Initializer {
  initialize() {
    return Promise.resolve()
  }

  afterInitialize() {
    const application = new Application()
    const ret = application.start()
    const context = require.context("../controllers", true, /\.js$/)
    application.load(definitionsFromContext(context))

    ret.then(() => console.log("stimulus is started"))

    return ret
  }
}
