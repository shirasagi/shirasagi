import { Controller } from "@hotwired/stimulus"

const instances = []

export default class extends Controller {
  static values = { targetName: String, radioName: String }

  connect() {
    if (!this.targetNameValue) {
      return
    }
    if (!this.radioNameValue) {
      return
    }

    this.targetElement = this.element.querySelector(`[name='${this.targetNameValue}']`)
    if (!this.targetElement) {
      return
    }

    this.radioElement = this.element.querySelector(`[name='${this.radioNameValue}']`)
    if (!this.radioElement) {
      return
    }

    this.radioElement.addEventListener("change", () => {
      this.update()
      instances.forEach((e) => {
        if (e.radioNameValue === this.radioNameValue && e !== this) {
          e.update()
        }
      })
    });

    instances.push(this)
    this.update()
  }

  disconnect() {
    const found = instances.find((e) => e === this)
    if (found < 0) {
      return
    }

    instances.splice(found, 1)
  }

  update() {
    if (this.radioElement.checked) {
      this.checked()
    } else {
      this.unchecked()
    }
  }

  checked() {
    if (!this.targetElement) {
      return
    }
    this.targetElement.value = this.radioElement.value
  }

  unchecked() {
    if (!this.targetElement) {
      return
    }
    this.targetElement.value = null
  }
}
