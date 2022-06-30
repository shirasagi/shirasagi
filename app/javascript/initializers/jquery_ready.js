import Initializer from "../ss/initializer"

export default class extends Initializer {
  initialize() {
    if ("jQuery" in window) {
      if (jQuery.isReady) {
        console.log("jquery is ready")
        return Promise.resolve()
      } else {
        return new Promise(resolve => {
          jQuery(() => {
            console.log("jquery is ready")
            resolve()
          })
        })
      }
    } else {
      console.log("jquery is not available")
      return Promise.resolve()
    }
  }
}
