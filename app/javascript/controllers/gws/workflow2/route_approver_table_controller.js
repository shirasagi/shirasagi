import { Controller } from "@hotwired/stimulus"

const LEVEL_SELECTORS = [
  "[name='item[approvers][][level]']",
  "[name='item[circulations][][level]']",
  "[name='item[workflow_approvers][][level]']",
  "[name='item[workflow_circulations][][level]']"
]

export default class extends Controller {
  connect() {
    this.element.addEventListener("click", (ev) => {
      const target = ev.target
      if (target.name && target.name === "add-row") {
        this.#addRow(target)
      }
      if (target.name && target.name === "delete-row") {
        this.#deleteRow(target)
      }
    })
    this.element.addEventListener("gws:workflow2:change-approver", (ev) => {
      this.#updateRowData(ev.target, ev.detail)
    })
  }

  #addRow(btnElement) {
    const templateElement = document.querySelector(this.element.dataset.rowTemplateRef)
    const cloneElement = templateElement.content.cloneNode(true)

    LEVEL_SELECTORS.forEach((selector) => {
      const levelElement = cloneElement.querySelector(selector)
      if (levelElement) {
        levelElement.value = this.element.dataset.level
      }
    })
    btnElement.closest(".index").querySelector("tbody").appendChild(cloneElement)
  }

  #deleteRow(btnElement) {
    btnElement.closest("tr").remove()
  }

  #updateRowData(target, detail) {
    const trElement = target.closest("tr")
    trElement.dataset.userType = detail.userType
    trElement.dataset.userId = detail.userId
  }
}
