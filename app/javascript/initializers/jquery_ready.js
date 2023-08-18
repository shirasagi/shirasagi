import Initializer from "../ss/initializer"

export default class extends Initializer {
  initialize() {
    if ("jQuery" in window) {
      if (jQuery.isReady) {
        return Promise.resolve()
      } else {
        return new Promise(resolve => {
          jQuery(() => {
            resolve()
          })
        })
      }
    } else {
      return Promise.resolve()
    }
  }
}
