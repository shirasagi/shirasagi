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
    this._modalResultEventHandler = undefined
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
    this._dialog.addEventListener("ss:modal-result", this.#modalResultEventHandler)
  }

  disconnect() {
    this._dialog.removeEventListener("ss:modal-result", this.#modalResultEventHandler)
    if (!this._attached) {
      this._dialogContainer.remove()
    }
  }

  get #modalResultEventHandler() {
    if (this._modalResultEventHandler) {
      return this._modalResultEventHandler
    }

    this._modalResultEventHandler = (ev) => this._observer.modalResult(ev)
    return this._modalResultEventHandler
  }

  get open() {
    if (!this._dialog) {
      return false
    }

    return this._dialog.open
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

  renderContent(content) {
    replaceChildren(this._dialogContent, content);
  }
}

export default class Dialog {
  constructor(src, options) {
    this.src = src
    this.options = options
    this._dialogFrame = undefined
    this._dialogClosed = undefined
  }

  static showModal(src, { source = undefined, data = undefined } = {}) {
    const dialog = new Dialog(src, { source, data })
    return dialog.showModal()
  }

  get open() {
    if (!this._dialogFrame) {
      return false
    }
    return this._dialogFrame.open
  }

  async showModal() {
    this._dialogFrame = undefined
    const ret = new Promise((resolve) => this._dialogClosed = resolve)

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

    // ダイアログを開く際、上から降ってくるようなアニメーションをする。
    // このアニメーションの終了まで待機してから "ss:dialog:opened" イベントは発火させるが、
    // アニメーションの待機中にダイアログが閉じてしまう可能性が 1mm ぐらい存在する。
    // そこで、開いている場合にのみ "ss:dialog:opened" イベントを発火させるようにする
    if (this.open) {
      dispatchEvent(this._dialogFrame._dialog, "ss:dialog:opened")
    }
    return ret
  }

  modalResult(ev) {
    if (this._dialogClosed) {
      this._dialogClosed(ev.detail)
    }
    if (this._dialogFrame?._dialog) {
      dispatchEvent(this._dialogFrame._dialog, "ss:dialog:closed")
    }
    requestAnimationFrame(() => {
      if (this._dialogFrame) {
        this._dialogFrame.disconnect()
      }
      if (this.options?.source) {
        dispatchEvent(this.options.source, "modalresult", ev.detail, { cancelable: false })
      }
    })
  }
}
