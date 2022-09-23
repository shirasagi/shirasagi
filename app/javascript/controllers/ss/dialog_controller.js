import { Controller } from "@hotwired/stimulus"
import axios from 'axios'
import Dialog from '../../ss/dialog'

export default class extends Controller {
  static values = {
    href: String
  }

  initialize() {
  }

  connect() {
    this.element.addEventListener("click", (ev) => {
      this.openDialog()
      ev.preventDefault()
      return false
    })
  }

  openDialog() {
    const url = this.hrefValue || this.element.href || this.element.dataset.href
    if (!url) {
      return
    }

    axios.get(url, { headers: { 'X-SS-DIALOG': 'normal' } })
      .then(async (response) => {
        await Dialog.loadHtml(response.data)
        await Dialog.open()
      })
  }

  disconnect() {
  }
}
