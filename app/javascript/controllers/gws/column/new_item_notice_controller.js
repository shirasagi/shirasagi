import { Controller } from "@hotwired/stimulus"
import Dialog from "../../../ss/dialog";

export default class extends Controller {
  connect() {
    this.handler = (ev) => {
      if (ev.target.classList.contains("gws-column-item-detail-link")) {
        this.#openDetaiEdit(ev.target)
        ev.preventDefault()
        return false
      }
    }
    this.element.addEventListener("click", this.handler)
  }

  disconnect() {
    this.element.removeEventListener("click", this.handler)
  }

  #openDetaiEdit(linkElement) {
    if (!linkElement.href) {
      return
    }

    const frameElement = this.element.closest("turbo-frame")
    if (!frameElement) {
      Dialog.showModal(linkElement.href)
      return
    }

    const closeButtonElement = frameElement.querySelector(".btn-close")
    if (!closeButtonElement) {
      Dialog.showModal(linkElement.href)
    }

    frameElement.addEventListener("turbo:before-fetch-request", (ev) => {
      if (!ev.defaultPrevented) {
        Dialog.showModal(linkElement.href)
      }
    }, { once: true })
    closeButtonElement.click()
  }
}
