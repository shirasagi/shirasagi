import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this.element.dataset.selected) {
      const optionElement = this.element.querySelector(`option[value="${this.element.dataset.selected}"]`)
      if (optionElement) {
        optionElement.selected = true;
      }
    }

    this.element.removeAttribute("disabled");
    this.element.setAttribute("aria-busy", "false");
  }
}
