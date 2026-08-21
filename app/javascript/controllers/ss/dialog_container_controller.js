import { Controller } from "@hotwired/stimulus";
import { dispatchEvent, formDataToRailsStyleJson } from "../../ss/tool";

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
    const detail = this._selectedResult ? this._selectedResult : this.#buildResult()
    if (this.hasResultTarget) {
      this.resultTarget.textContent = JSON.stringify(detail)
    }
    dispatchEvent(this.dialogTarget, "ss:modal-result", detail)
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

    if (!this._selectedResult) {
      this._selectedResult = {}
    }
    if (!this._selectedResult.returnValue) {
      this._selectedResult.returnValue = "send"
    }
    if (data) {
      if (!this._selectedResult.items) {
        this._selectedResult.items = []
      }
      this._selectedResult.items.push(data)
    }

    if (this.hasResultTarget) {
      this.resultTarget.textContent = JSON.stringify(this._selectedResult)
    }
  }

  #buildResult() {
    const result = { "returnValue": this.dialogTarget.returnValue }

    if (this.hasDialogTarget) {
      const formElement = this.dialogTarget.querySelector("form")
      if (formElement) {
        const formData = new FormData(formElement)
        const item = formDataToRailsStyleJson(formData)
        result.items = [ item ]
      }
    }

    return result
  }
}
