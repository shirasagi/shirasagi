// jquery.colorbox.js を wrap する
// インターフェース仕様は HTMLDialogElement を参考にした

import {dispatchEvent, LOADING, replaceChildren} from "./tool";
import i18next from 'i18next'

const DIALOG_TEMPLATE = `
<div class="ss-dialog-container">
  <dialog class="ss-dialog">
    <div class="ss-dialog-header">
      <button type="button" name="close" class="ss-dialog-close" data-action="close-dialog" aria-label="close dialog">
        <span class="material-icons-outlined" aria-hidden="true" role="img">cancel</span>
      </button>
    </div>
    <div class="ss-dialog-content">
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
  static connect() {
    const instance = new DialogFrame()
    instance.#connect()
    return instance
  }

  static attach(element) {
    const instance = new DialogFrame()
    instance.#attach(element)
    return instance
  }

  constructor() {
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

  disconnect() {
    this._dialogContainer.remove()
  }

  get observer() {
    return this._observer
  }

  set observer(value) {
    this._observer = value
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

  closeModal() {
    const event = dispatchEvent(this._dialog, "ss:dialog:closing")
    if (event.defaultPrevented) {
      return
    }
    this._dialog.close()
  }

  renderContent(content) {
    replaceChildren(this._dialogContent, content);
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
    if (!this._attached) {
      this._dialogContent.innerHTML = LOADING
    }
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

    let promise1;
    if (this.options && this.options.attach) {
      this._dialogFrame = DialogFrame.attach(this.src)
      promise1 = new Promise((resolve) => {
        this._dialogFrame.observer = {
          onClose: () => this.#onClose(resolve),
          onSelect: ($itemEl) => this.#onSelect($itemEl)
        }
      })

      await this._dialogFrame.showModal()
    } else {
      this._dialogFrame = DialogFrame.connect()
      promise1 = new Promise((resolve) => {
        this._dialogFrame.observer = {
          onClose: () => this.#onClose(resolve),
          onSelect: ($itemEl) => this.#onSelect($itemEl)
        }
      })
      const promise2 = this._dialogFrame.showModal()

      if (this.src instanceof HTMLTemplateElement) {
        this._dialogFrame.renderContent(this.src.content.cloneNode(true))
      } else if (this.src instanceof HTMLElement) {
        this._dialogFrame.renderContent(this.src.cloneNode(true))
      } else if (this.src instanceof DocumentFragment) {
        this._dialogFrame.renderContent(this.src)
      } else {
        const response = await fetch(this.src, {headers: {'X-SS-DIALOG': true}})
        const html = await response.text()
        this._dialogFrame.renderContent(html)
      }
      await promise2
    }
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
    setTimeout(() => this._dialogFrame.disconnect(), 11)
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
