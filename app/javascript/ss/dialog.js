// jquery.colorbox.js を wrap する
// インターフェース仕様は HTMLDialogElement を参考にした

import {dispatchEvent} from "./tool";

export class ColorBoxDialog {
  constructor(src, options) {
    this.src = src
    this.options = options
    this._open = false
    this._returnValue = undefined
  }

  static showModal(src, options) {
    const dialog = new Dialog(src, options)
    return dialog.showModal()
  }

  get open() {
    return this._open;
  }

  get returnValue() {
    return this._returnValue;
  }

  showModal() {
    this._open = false
    this._returnValue = undefined

    return new Promise((resolve) => {
      $.colorbox({
        href: this.src, width: "90%", height: "90%", fixed: true, open: true,
        onOpen: () => this.#onOpen(), onLoad: () => this.#onLoad(), onComplete: () => this.#onComplete(),
        onCleanup: () => this.#onCleanup(), onClosed: () => { this.#onClosed(); resolve(this) }
      })
    })
  }

  #onOpen() {}
  #onLoad() {}

  #onComplete() {
    const $el = $.colorbox.element()
    $el.data("on-select", ($itemEl) => this.#onSelect($itemEl))
    this._open = true
  }

  #onCleanup() {}
  #onClosed() {
    this._open = false
  }

  #onSelect($itemEl) {
    const $dataEl = $itemEl.closest("[data-id]")
    var data = $dataEl.data();
    if (!data.name) {
      data.name = $dataEl.find(".select-item").html() || $itemEl.text() || $dataEl.text();
    }

    if (!this._returnValue) {
      this._returnValue = []
    }
    this._returnValue.push(data)
    this.ok = true
  }
}

const SPINNER_TEMPLATE = `<img style="vertical-align:middle" src="/assets/img/loading.gif" alt="loading.." width="16" height="11" />`

const DIALOG_TEMPLATE = `
<div id="ss-dialog-container" class="ss-dialog-container">
  <dialog id="ss-dialog" class="ss-dialog">
    <div class="ss-dialog-header">
      <button type="button" name="close" class="ss-dialog-close" id="ss-dialog-close" data-action="close-dialog">
        <span class="material-icons-outlined">cancel</span>
      </button>
    </div>
    <turbo-frame id="ss-dialog-content" class="ss-dialog-content">
      ${SPINNER_TEMPLATE}
    </turbo-frame>
  </dialog>
</div>`

class DialogFrame {
  static _instance

  static instance() {
    if (DialogFrame._instance) {
      return DialogFrame._instance
    }

    DialogFrame._instance = new DialogFrame()
    DialogFrame._instance.#connect()
    return DialogFrame._instance
  }

  constructor() {
    this.dialogTemplate = document.createElement("template")
    this.dialogTemplate.innerHTML = DIALOG_TEMPLATE
  }

  #connect() {
    document.body.appendChild(this.dialogTemplate.content.cloneNode(true))

    // this._dialogContainer = document.getElementById("ss-dialog-container")
    this._dialog = document.getElementById("ss-dialog")
    this._dialogContent = this._dialog.querySelector(".ss-dialog-content")
    this._dialog.addEventListener("click", (ev) => {
      if (ev.target.dataset.action && ev.target.dataset.action === "close-dialog") {
        this.closeModal()
        return
      }

      const actionElement = ev.target.closest("[data-action]")
      if (actionElement && actionElement.dataset.action && actionElement.dataset.action === "close-dialog") {
        this.closeModal()
        return
      }
    })

    this._dialog.addEventListener("cancel", () => this.#onCancel())
    this._dialog.addEventListener("close", () => this.#onClose())
    this._dialogContent.addEventListener("ss:modal-close", () => this.closeModal())
    this._dialogContent.addEventListener("ss:modal-select", (ev) => this.#onSelect(ev.detail.item))
  }

  get observer() {
    return this._observer
  }

  set observer(value) {
    this._observer = value
  }

  showModal() {
    SS_SearchUI.dialogType = 'ss'
    this._dialogContent.innerHTML = SPINNER_TEMPLATE
    this._dialog.showModal()
    return new Promise((resolve) => {
      this._dialog.addEventListener("animationend", () => resolve(), { once: true })
    })
  }

  closeModal() {
    const event = dispatchEvent(this._dialog, "ss:dialog:closing")
    if (event.defaultPrevented) {
      return
    }
    this._dialog.close()
  }

  renderContent(content) {
    if (typeof content === 'string') {
      this._dialogContent.innerHTML = content
    } else {
      this._dialogContent.replaceChildren(content)
    }

    // execute javascript within dialog-content
    this._dialogContent.querySelectorAll("script").forEach((scriptElement) => {
      const newScriptElement = document.createElement("script")
      Array.from(scriptElement.attributes).forEach(attr => newScriptElement.setAttribute(attr.name, attr.value))
      newScriptElement.appendChild(document.createTextNode(scriptElement.innerHTML))
      scriptElement.parentElement.replaceChild(newScriptElement, scriptElement)
    })
  }

  #onCancel() {
    if (this._observer && this._observer.onCancel) {
      this._observer.onCancel()
    }
  }

  #onClose() {
    if (this._observer && this._observer.onClose) {
      this._observer.onClose()
    }
    this._dialogContent.innerHTML = SPINNER_TEMPLATE
    SS_SearchUI.dialogType = 'colorbox'
  }

  #onSelect(item) {
    if (this._observer && this._observer.onSelect) {
      this._observer.onSelect(item)
    }
  }
}

export default class Dialog {
  constructor(src, options) {
    this.src = src
    this.options = options
    this._open = false
    this._returnValue = undefined
  }

  static showModal(src, options) {
    const dialog = new Dialog(src, options)
    return dialog.showModal()
  }

  get open() {
    return this._open;
  }

  get returnValue() {
    return this._returnValue;
  }

  async showModal() {
    this._open = false
    this._returnValue = undefined
    this._dialogFrame = undefined

    this._dialogFrame = DialogFrame.instance()
    const promise1 = new Promise((resolve) => {
      this._dialogFrame.observer = {
        onClose: () => this.#onClose(resolve),
        onSelect: ($itemEl) => this.#onSelect($itemEl)
      }
    })
    const promise2 = this._dialogFrame.showModal()

    if (this.src instanceof HTMLElement) {
      this._dialogFrame.renderContent(this.src.content.cloneNode(true))
    } else if (this.src instanceof DocumentFragment) {
      this._dialogFrame.renderContent(this.src)
    } else {
      const response = await fetch(this.src, { headers: { 'X-SS-DIALOG': true } })
      const html = await response.text()
      this._dialogFrame.renderContent(html)
    }
    await promise2
    this._open = true
    dispatchEvent(this._dialogFrame._dialog, "ss:dialog:opened")

    return await promise1
  }

  #onClose(resolve) {
    if (this._dialogFrame._dialog.returnValue === 'send' && !this._returnValue) {
      const formElement = this._dialogFrame._dialog.querySelector("form")
      if (formElement) {
        const formData = new FormData(formElement)
        this._returnValue = Array.from(formData.entries())
      }
    }

    this._open = false
    this._dialogFrame.observer = undefined
    resolve(this)
    dispatchEvent(this._dialogFrame._dialog, "ss:dialog:closed")
  }

  #onSelect($itemEl) {
    const $dataEl = $itemEl.closest("[data-id]")
    var data = $dataEl.data();
    if (!data.name) {
      data.name = $dataEl.find(".select-item").html() || $itemEl.text() || $dataEl.text();
    }

    if (!this._returnValue) {
      this._returnValue = []
    }
    this._returnValue.push(data)
    this.ok = true
  }
}
