import Initializer from "../ss/initializer"
import i18next from 'i18next'
import en from "../locales/en.json"
import ja from "../locales/ja.json"

export default class extends Initializer {
  initialize() {
    return new Promise((resolve, reject) => {
      i18next.init({
        resources: {
          ja, en
        },
        fallbackLng: ['en', 'ja']
      }, (err, t) => {
        if (err) {
          reject(err)
        } else {
          resolve()
        }
      })
    })
  }

  afterInitialize() {
    i18next.changeLanguage(document.documentElement.lang)
    console.log(`i18next is ready: ss.basic_info=${i18next.t("ss.basic_info")}`)
    return Promise.resolve()
  }
}
