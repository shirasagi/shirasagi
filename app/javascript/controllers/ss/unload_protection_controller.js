import { Controller } from "@hotwired/stimulus"
import i18next from 'i18next'

class ConfirmationService {
  static #started = false;
  static #subjects = [];

  static start() {
    if (ConfirmationService.#started) {
      return;
    }

    window.addEventListener("beforeunload", (ev) => {
      return ConfirmationService.#beforeUnload(ev)
    })
    ConfirmationService.#started = true
  }

  static add(subject) {
    ConfirmationService.#subjects.push(subject)
  }

  static remove(subject) {
    const newSubjects = ConfirmationService.#subjects.filter((item) => item !== subject)
    ConfirmationService.#subjects = newSubjects
  }

  static #beforeUnload(ev) {
    if (SS.disableConfirmUnloading) {
      return;
    }

    const changed = ConfirmationService.#subjects.some(subject => subject.isChanged())
    if (!changed) {
      return;
    }

    ev.returnValue = i18next.t('ss.confirm.unload')
    ev.preventDefault()
    return i18next.t('ss.confirm.unload')
  }
}

export default class extends Controller {
  #changed = false

  connect() {
    ConfirmationService.start();
    ConfirmationService.add(this);

    this.element.addEventListener("change", (ev) => {
      if (Array.from(this.element.elements).some((elem => elem === ev.target))) {
        this.#changed = true
        this.element.classList.add("changed")
      }
    })

    this.#preventFromUnloadingTurboFrame()
    this.#preventFromClosingDialog()
  }

  disconnect() {
    if (this.#turboFrameElement) {
      this.#turboFrameElement.removeEventListener("turbo:before-fetch-request", this.#beforeFetchRequesthandler)
      this.#turboFrameElement.removeEventListener("turbo:submit-end", this.#submitEndHandler)
    }
    if (this.#dialogElement) {
      this.#dialogElement.removeEventListener("ss:dialog:closing", this.#dialogClosingHandler)
    }
    ConfirmationService.remove(this);
  }

  isChanged() {
    return this.#changed;
  }

  #preventFromUnloadingTurboFrame() {
    if (!this.#turboFrameElement) {
      return
    }

    this.#turboFrameElement.addEventListener("turbo:before-fetch-request", this.#beforeFetchRequesthandler)
    this.#turboFrameElement.addEventListener("turbo:submit-end", this.#submitEndHandler)
  }

  #preventFromClosingDialog() {
    if (!this.#dialogElement) {
      return
    }

    this.#dialogElement.addEventListener("ss:dialog:closing", this.#dialogClosingHandler)
  }

  get #turboFrameElement() {
    if ('_turboFrame' in this) {
      return this._turboFrame
    }

    this._turboFrame = this.element.closest("turbo-frame")
    return this._turboFrame
  }

  get #beforeFetchRequesthandler() {
    if ('_beforeFetchRequesthandler' in this) {
      return this._beforeFetchRequesthandler
    }

    this._beforeFetchRequesthandler = (ev) => {
      if (ev.target !== this.#turboFrameElement) {
        return
      }
      if (!this.#changed) {
        return
      }
      if (confirm(i18next.t('ss.confirm.unload'))) {
        return
      }
      ev.preventDefault();
    }
    return this._beforeFetchRequesthandler
  }

  get #submitEndHandler() {
    if ('_submitEndHandler' in this) {
      return this._submitEndHandler
    }

    this._submitEndHandler = (ev) => {
      if (ev.detail.success) {
        this.#changed = false
      }
    }
    return this._submitEndHandler
  }

  get #dialogElement() {
    if ('_dialog' in this) {
      return this._dialog
    }

    this._dialog = this.element.closest("dialog")
    return this._dialog
  }

  get #dialogClosingHandler() {
    if ('_dialogClosingHandler' in this) {
      return this._dialogClosingHandler
    }

    this._dialogClosingHandler = (ev) => {
      if (ev.target !== this.#dialogElement) {
        return
      }
      if (!this.#changed) {
        return
      }
      if (confirm(i18next.t('ss.confirm.unload'))) {
        return
      }
      ev.preventDefault();
    }
    return this._dialogClosingHandler
  }
}
