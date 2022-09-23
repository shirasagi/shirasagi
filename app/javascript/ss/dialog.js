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
