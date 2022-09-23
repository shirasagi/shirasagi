import i18next from 'i18next'

function documentReady() {
  if (document.readyState === "complete") {
    return Promise.resolve()
  }

  return new Promise((resolve, _reject) => {
    window.addEventListener('DOMContentLoaded', () => {
      resolve()
    })
  })
}

const FILENAME_REGEX = /filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/;

function parseContentDisposition(disposition) {
  var matches = FILENAME_REGEX.exec(disposition);
  if (matches != null && matches[1]) {
    return matches[1].replace(/['"]/g, '');
  }
}


function downloadFile(response) {
  const filename = parseContentDisposition(response.headers.get('content-disposition'))

  return new Promise((resolve, _reject) => {
    response.blob().then((blob) => {
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.classList.add("hide")
      a.href = url
      if (filename) {
        a.download = filename
      }
      document.body.appendChild(a);
      a.click();
      setTimeout(() => { a.remove() }, 250)
      resolve()
    })
  })
}

export default class Dialog {
  static #instance

  static async instance() {
    if (this.#instance) {
      return this.#instance
    }

    await documentReady()

    let dialogEl = document.getElementById("ss-dialog")
    if (dialogEl) {
      this.#instance = new Dialog(dialogEl)
      return this.#instance
    }

    const wrapper = document.createElement("div")
    wrapper.classList.add("ss-dialog-wrap")
    wrapper.innerHTML = `<dialog id="ss-dialog" class="ss-dialog"></dialog>`

    document.body.appendChild(wrapper);

    dialogEl = document.getElementById("ss-dialog")
    this.#instance = new Dialog(dialogEl)
    return this.#instance
  }

  static tryInstance() {
    return this.#instance
  }

  static async loadHtml(html) {
    const instance = await this.instance()
    instance.loadHtml(html)
  }

  static async open() {
    const instance = this.tryInstance()
    if (!instance) {
      throw "no dialogs are ready"
    }

    instance.open()
  }

  static async close(...args) {
    const instance = this.tryInstance()
    if (instance) {
      return instance.close(...args)
    }
  }

  constructor(dialogEl) {
    this.element = dialogEl

    this.element.addEventListener("click", (ev) => {
      if (ev.target.name === "close") {
        if (ev.target.dataset.value) {
          this.close(ev.target.dataset.value)
        } else {
          this.close()
        }
      }
    })
    this.element.addEventListener("turbo:before-fetch-request", (ev) => {
      ev.detail.fetchOptions.headers["X-SS-DIALOG"] = "normal"
    })
    this.element.addEventListener("turbo:submit-end", async (ev) => {
      const response = ev.detail.fetchResponse.response
      if (response.ok && response.headers.get('content-disposition')) {
        await downloadFile(response)
        this.close()
        SS.notice(i18next.t("ss.notice.downloaded"))
        return
      }
    })
  }

  loadHtml(html) {
    this.element.innerHTML = html
  }

  open() {
    this.element.showModal()
  }

  close(...args) {
    this.element.close(...args)
  }
}
