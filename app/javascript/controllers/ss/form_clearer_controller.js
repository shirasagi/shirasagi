import { Controller } from "@hotwired/stimulus"

function isAncestor(parent, element) {
  while (element &&  element !== document.body && element !== document) {
    if (parent === element) {
      return true;
    }

    element = element.parentElement
  }

  return false
}

export default class extends Controller {
  clear() {
    const form = this.element.closest("form")
    Array.from(form.elements).forEach(element => {
      if (isAncestor(this.element, element)) {
        if ('type' in element && (element.type === "radio" || element.type === "checkbox" || element.type === "button" || element.type === "submit" || element.type === "reset")) {
          console.log(element)
          element.checked = false;
        } else {
          element.value = null
        }
      }
    })
  }
}
