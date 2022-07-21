import Initializer from "../ss/initializer"
import i18next from 'i18next'
import Multiload from 'i18next-multiload-backend-adapter'
import Http from 'i18next-http-backend'

export default class extends Initializer {
  initialize() {
    return new Promise((resolve, reject) => {
      i18next
        .use(Multiload)
        .init({
          backend: {
            backend: Http,
            backendOption: {
              loadPath: '/.mypage/locales/default/{{lng}}/{{ns}}.json',
              //addPath: '/.mypage/locales/fallback/{{lng}}/{{ns}}.json',
              allowMultiLoading: true
            }
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
