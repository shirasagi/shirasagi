import Initializer from "../ss/initializer"

export default class extends Initializer {
  initialize() {
    if ("jQuery" in window) {
      if (jQuery.isReady) {
        SS.updateConfig({ map: MAP_CONFIG, ss: SS_CONFIG })
        return Promise.resolve()
      } else {
        return new Promise(resolve => {
          jQuery(() => {
            SS.updateConfig({ map: MAP_CONFIG, ss: SS_CONFIG })
            resolve()
          })
        })
      }
    } else {
      return Promise.resolve()
    }
  }
}
