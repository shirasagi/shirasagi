import Initializer from "./ss/initializer"

Initializer.load(require.context("./initializers", true, /\.js$/i))
Initializer.ready(() => {
  SS.doneReady()
})

if (SS.readyTimeout) {
  clearTimeout(SS.readyTimeout)
  SS.readyTimeout = null
}
