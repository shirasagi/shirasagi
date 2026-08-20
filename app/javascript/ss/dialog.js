// jquery.colorbox.js を wrap する
// インターフェース仕様は HTMLDialogElement を参考にした

import {dispatchEvent, LOADING, replaceChildren} from "./tool";
import i18next from 'i18next'

const DIALOG_TEMPLATE = `
<div class="ss-dialog-container" data-controller="ss--dialog-container" data-ss--dialog-container-target="container">
  <dialog class="ss-dialog" data-ss--dialog-container-target="dialog">
    <div class="ss-dialog-header">
      <button type="button" name="close" class="ss-dialog-close" data-action="ss--dialog-container#closeDialog" aria-label="close dialog">
        <span class="material-icons-outlined" aria-hidden="true" role="img">cancel</span>
      </button>
    </div>
    <div class="ss-dialog-content" data-ss--dialog-container-target="content">
      ${LOADING}
    </div>
    <script type="application/json" data-ss--dialog-container-target="result">
    </script>
  </dialog>
</div>`

function findDialogContainer(element) {
  if (element.classList.contains("ss-dialog-container")) {
    return element;
  }
  return element.querySelector(".ss-dialog-container");
}

class DialogFrame {
  static connect(observer) {
    const instance = new DialogFrame(observer)
    instance.#connect()
    return instance
  }

  static attach(observer, element) {
    const instance = new DialogFrame(observer)
    instance.#attach(element)
    return instance
  }

  constructor(observer) {
    this._observer = observer
  }

  #connect() {
    const dialogTemplate = document.createElement("template")
    dialogTemplate.innerHTML = DIALOG_TEMPLATE.replaceAll("close dialog", i18next.t("ss.buttons.close"))

    this._attached = false;
    this._dialogContainer = document.body.appendChild(dialogTemplate.content.firstElementChild)
    this._dialog = this._dialogContainer.querySelector(".ss-dialog")
    this._dialogContent = this._dialog.querySelector(".ss-dialog-content")
    this.#bind();
  }

  #attach(element) {
    this._attached = true;
    this._dialogContainer = findDialogContainer(element);
    this._dialog = this._dialogContainer.querySelector(".ss-dialog")
    this._dialogContent = this._dialog.querySelector(".ss-dialog-content")
    this.#bind();
  }

  #bind() {
    this._dialog.addEventListener("close", this.#closeEventHandler)
  }

  disconnect() {
    this._dialog.removeEventListener("close", this.#closeEventHandler)
    if (!this._attached) {
      this._dialogContainer.remove()
    }
  }

  get #closeEventHandler() {
    if ('_closeEventHandler' in this) {
      return this._closeEventHandler
    }

    this._closeEventHandler = (ev) => this._observer.onClose(ev)
    return this._closeEventHandler
  }

  showModal() {
    SS_SearchUI.dialogType = 'ss'
    if (!this._attached) {
      this._dialogContent.innerHTML = LOADING
    }
    this._dialog.showModal()
    return new Promise((resolve) => {
      this._dialog.addEventListener("animationend", () => resolve(), { once: true })
    })
  }

  // closeModal() {
  //   this._dialog.requestClose()
  // }

  renderContent(content) {
    replaceChildren(this._dialogContent, content);
  }

  dialogResult() {
    const result = this.#parseDialogResult()
    if (!result.returnValue) {
      result.returnValue = this._dialog.returnValue
    }
    return result
  }

  #parseDialogResult() {
    const dialogResult = this._dialog.querySelector(`[data-ss--dialog-container-target="result"]`)
    let json = dialogResult?.textContent?.trim()
    if (json) {
      return JSON.parse(json)
    } else {
      return {}
    }
  }
}

export default class Dialog {
  constructor(src, options) {
    this.src = src
    this.options = options
    this._open = false
    this._dialogClosed = undefined
  }

  static showModal(src, options) {
    const dialog = new Dialog(src, options)
    return dialog.showModal()
  }

  get open() {
    return this._open;
  }

  async showModal() {
    this._open = false
    this._dialogFrame = undefined

    // let promise1;
    if (this.options && this.options.attach) {
      this._dialogFrame = DialogFrame.attach(this, this.src)

      await this._dialogFrame.showModal()
    } else {
      this._dialogFrame = DialogFrame.connect(this)
      await this._dialogFrame.showModal()

      if (this.src instanceof HTMLTemplateElement) {
        this._dialogFrame.renderContent(this.src.content.cloneNode(true))
      } else if (this.src instanceof HTMLElement) {
        this._dialogFrame.renderContent(this.src.cloneNode(true))
      } else if (this.src instanceof DocumentFragment) {
        this._dialogFrame.renderContent(this.src)
      } else {
        const fetchOptions = { method: this.options?.data ? "POST" : "GET", headers: { 'X-SS-DIALOG': true } }
        if (this.options?.data) {
          fetchOptions.body = this.options.data
        }
        const response = await fetch(this.src, fetchOptions)
        const html = await response.text()
        this._dialogFrame.renderContent(html)
      }
    }
    this._open = true
    dispatchEvent(this._dialogFrame._dialog, "ss:dialog:opened")
    return new Promise((resolve) => this._dialogClosed = resolve)
  }

  onClose(_ev) {
    this._open = false
    this._dialogClosed(this._dialogFrame.dialogResult())
    dispatchEvent(this._dialogFrame._dialog, "ss:dialog:closed")
    requestAnimationFrame(() => this._dialogFrame.disconnect())
  }
}
