import Initializer from "../ss/initializer"
import i18next from 'i18next'
import MultiLoad from 'i18next-multiload-backend-adapter'
import Http from 'i18next-http-backend'

const LOAD_PATH = '/.mypage/locales/default/{{lng}}/{{ns}}.json'

function initializeI18nextViaRemote(resolve, reject) {
  i18next
    .use(MultiLoad)
    .init({
      backend: {
        backend: Http,
        backendOption: {
          loadPath: LOAD_PATH,
          //addPath: '/.mypage/locales/fallback/{{lng}}/{{ns}}.json',
          allowMultiLoading: true
        }
      },
      fallbackLng: ['en', 'ja']
    }, (err, _t) => {
      if (err) {
        reject(err)
      } else {
        resolve()
      }
    })
}

function initializeI18nextViaLocal(resolve, reject) {
  i18next.init({
    resources: I18NEXT_RESOURCES,
    fallbackLng: ['en', 'ja']
  }, (err, _t) => {
    if (err) {
      reject(err)
    } else {
      resolve()
    }
  })
}

export default class extends Initializer {
  initialize() {
    return new Promise((resolve, reject) => {
      if (RAILS_ENV === "production") {
        initializeI18nextViaLocal(resolve, reject)
      } else {
        initializeI18nextViaRemote(resolve, reject)
      }
    })
  }

  afterInitialize() {
    i18next.changeLanguage(document.documentElement.lang)
    console.log(`i18next is ready: ss.basic_info=${i18next.t("ss.basic_info")}`)
    return Promise.resolve()
  }
}
