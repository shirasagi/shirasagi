import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this.element.dataset.currentSelect) {
      const optionElement = this.element.querySelector(`option[value="${this.element.dataset.currentSelect}"]`)
      if (optionElement) {
        optionElement.selected = true;
      }
    }
  }
}
