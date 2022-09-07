import Initializer from "../ss/initializer"
import i18next from 'i18next'
import MultiLoad from 'i18next-multiload-backend-adapter'
import Http from 'i18next-http-backend'
import moment from "moment/moment"

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
      fallbackLng: AVAILABLE_LOCALES
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
    fallbackLng: AVAILABLE_LOCALES
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
    i18next.changeLanguage(document.documentElement.lang || 'ja')
    moment.locale(document.documentElement.lang || 'ja');

    window.i18next = i18next
    window.moment = moment

    return Promise.resolve()
  }
}
