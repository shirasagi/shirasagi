import { Controller } from "@hotwired/stimulus"
import { isSafari } from "../../ss/tool"

export default class extends Controller {
  static values = {
    submitter: String
  }

  connect() {
    this.element.addEventListener("change", (ev) => this.submit(ev.target))
  }

  submit(selectElement) {
    if (!selectElement) {
      return
    }

    if (selectElement.form) {
      this.submitForm(selectElement.form)
      return
    }

    const formElement = selectElement.closest("form")
    if (formElement) {
      this.submitForm(formElement)
      return
    }

    const index = selectElement.selectedIndex
    if (index < 0) {
      return
    }

    const optionElement = selectElement.options[index]
    if (optionElement) {
      this.submitViaAttributes(optionElement)
      return
    }
  }

  submitForm(formElement) {
    if (!this.submitterValue) {
      formElement.requestSubmit()
      return
    }

    let submitter = document.getElementById(this.submitterValue)
    if (!submitter) {
      submitter = formElement.querySelector(this.submitterValue)
    }
    if (!submitter) {
      formElement.requestSubmit()
      return
    }

    if (isSafari()) {
      submitter.click()
    } else {
      formElement.requestSubmit(submitter)
    }
  }

  submitViaAttributes(optionElement) {
    if (optionElement.href) {
      location.href = optionElement.href
      return
    }

    if (optionElement.dataset && optionElement.dataset.href) {
      location.href = optionElement.dataset.href
      return
    }
  }
}
