import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [ "container", "dialog", "content", "result" ]

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
    const detail = this._result ? this._result : { "returnValue": this.dialogTarget.returnValue }
    this.dispatch("ss:modal-result", { detail })
    SS_SearchUI.dialogType = 'colorbox'
  }

  #onSelect($itemEl) {
    const $dataEl = $itemEl.closest("[data-id]")
    var data
    if ($dataEl[0]) {
      data = $dataEl.data()
      if (!data.name) {
        data.name = $dataEl.find(".select-item").html() || $itemEl.text() || $dataEl.text()
      }
    }

    if (!this._result) {
      this._result = {}
    }
    if (!this._result.returnValue) {
      this._result.returnValue = "send"
    }
    if (data) {
      if (!this._result.items) {
        this._result.items = []
      }
      this._result.items.push(data)
    }
    this._result.ok = true

    if (this.hasResultTarget) {
      this.resultTarget.textContent = JSON.stringify(this._result)
    }
  }
}
