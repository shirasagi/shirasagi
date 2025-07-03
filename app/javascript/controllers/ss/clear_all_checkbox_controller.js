import { Controller } from "@hotwired/stimulus"

function isCheckbox(element) {
  return element.type && element.type === "checkbox"
}

function clearCheck(element) {
  if (element.checked) {
    element.checked = false;
    element.dispatchEvent(new Event("change", { bubbles: true, cancelable: true, composed: true }));
  }
}

export default class extends Controller {
  connect() {
    this.element.addEventListener("click", (ev) => {
      ev.preventDefault();
      this.clearAllCheckboxes();
      return false;
    })
  }

  clearAllCheckboxes() {
    Array.from(this.element.form.elements).forEach((element) => {
      if (isCheckbox(element)) {
        clearCheck(element);
      }
    })
  }
}
