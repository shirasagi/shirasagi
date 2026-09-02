import { Controller } from "@hotwired/stimulus";
import { dispatchEvent } from "../../ss/tool";

export default class extends Controller {
  static targets = [ "container", "dialog", "content" ]

  connect() {
    // console.log(`[${this.identifier}] connected`, this.hasDialogTarget);
    if (!this.hasDialogTarget) {
      return
    }

    this.dialogTarget.addEventListener("close", () => this.#onClose())
    this.dialogTarget.addEventListener("ss:modal-close", () => this.dialogTarget.requestClose())
    this.dialogTarget.addEventListener("ss:modal-select", (ev) => this.#onSelect(ev.detail.item))
  }

  closeDialog() {
    if (this.hasDialogTarget) {
      this.dialogTarget.requestClose()
    }
  }

  #onClose() {
    const detail = this.#buildResult()
    dispatchEvent(this.dialogTarget, "ss:modal-result", detail, { cancelable: false })
    SS_SearchUI.dialogType = 'colorbox'
  }

  #onSelect($itemEl) {
    const $dataEl = $itemEl.closest("[data-id]")
    if (!$dataEl[0]) {
      return
    }

    const data = $dataEl.data()
    if (!data) {
      return
    }
    if (!data.name) {
      data.name = $dataEl.find(".select-item").html() || $itemEl.text() || $dataEl.text()
    }

    if (!this._items) {
      this._items = []
    }
    this._items.push(data)
  }

  #buildResult() {
    const result = { "returnValue": this.dialogTarget.returnValue }

    if (this._items) {
      result.items = this._items
      result.returnValue = result.returnValue || "send"
    }

    if (this.hasDialogTarget) {
      const formElement = this.dialogTarget.querySelector("form")
      if (formElement) {
        result.formData = new FormData(formElement)
      }
    }

    return result
  }
}
