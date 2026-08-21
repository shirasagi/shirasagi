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
    // console.log(`[${this.identifier}] connected`);
  }

  clear() {
    Array.from(this.element.querySelectorAll("input")).forEach((element) => {
      if (isCheckbox(element)) {
        clearCheck(element);
      }
    })
  }
}
