import Initializer from "../ss/initializer"

export default class extends Initializer {
  initialize() {
    if ("jQuery" in window) {
      if (jQuery.isReady) {
        SS.updateConfig({ map: MAP_CONFIG_EXPORTS, ss: SS_CONFIG_EXPORTS })
        return Promise.resolve()
      } else {
        return new Promise(resolve => {
          jQuery(() => {
            SS.updateConfig({ map: MAP_CONFIG_EXPORTS, ss: SS_CONFIG_EXPORTS })
            resolve()
          })
        })
      }
    } else {
      return Promise.resolve()
    }
  }
}
