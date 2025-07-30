import { Controller } from "@hotwired/stimulus"
import {dispatchEvent} from "../../ss/tool";

export default class extends Controller {
  connect() {
    if (this.#turboFrameElement && this.#dialogElement) {
      this.#turboFrameElement.addEventListener("turbo:submit-end", this.#submitEndHandler)
    }
  }

  disconnect() {
    if (this.#turboFrameElement && this.#dialogElement) {
      this.#turboFrameElement.removeEventListener("turbo:submit-end", this.#submitEndHandler)
    }
  }

  get #turboFrameElement() {
    if ('_turboFrame' in this) {
      return this._turboFrame
    }

    this._turboFrame = this.element.closest("turbo-frame")
    return this._turboFrame
  }

  get #dialogElement() {
    if ('_dialog' in this) {
      return this._dialog
    }

    this._dialog = this.element.closest("dialog")
    return this._dialog
  }

  get #submitEndHandler() {
    if ('_submitEndHandler' in this) {
      return this._submitEndHandler
    }

    this._submitEndHandler = (ev) => {
      if (ev.detail.success) {
        dispatchEvent(this.element, "ss:modal-close")
      }
    }
    return this._submitEndHandler
  }
}
