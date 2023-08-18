import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  initialize() {
  }

  connect() {
    const selectElement = this.element.querySelector("select")
    if (selectElement) {
      selectElement.addEventListener("change", (ev) => this.updateDescription(selectElement))
      this.updateDescription(selectElement)
    }
  }

  disconnect() {
  }

  updateDescription(selectElement) {
    if (selectElement.selectedIndex < 0) {
      this.hideDescription(this.element.querySelector(".description"))
      return
    }

    const selectedOption = selectElement.options[selectElement.selectedIndex]
    if (!selectedOption) {
      this.hideDescription(this.element.querySelector(".description"))
      return
    }

    if (selectedOption.dataset.description) {
      this.showDescription(this.element.querySelector(".description"), selectedOption.dataset.description)
    } else {
      this.hideDescription(this.element.querySelector(".description"))
    }
  }

  showDescription(el, description) {
    el.classList.remove("hide")
    el.textContent = description
  }

  hideDescription(el) {
    el.classList.add("hide")
    el.textContent = ""
  }
}
