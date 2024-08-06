import { Controller } from "@hotwired/stimulus"
import { LOADING, csrfToken, dispatchEvent } from "../../../ss/tool"

function isPlacementTop(placement) {
  return !isPlacementBottom(placement)
}
function isPlacementBottom(placement) {
  return placement === "bottom"
}

export default class extends Controller {
  static values = {
    url: String,
    target: String,
    placement: String
  }

  connect() {
    this.element.addEventListener("click", (ev) => {
      if (ev.target.classList.contains("btn-create-column") && ev.target.dataset.route) {
        this.createColumn(ev.target.dataset.route)
      }
    })
  }

  async createColumn(route) {
    const newFrame = await this.addNewFrame()

    const data = { type: route, placement: this.placementValue }
    const response = await fetch(
      this.urlValue,
      { method: 'POST', headers: { "X-CSRF-Token": csrfToken(), 'Content-Type': 'application/json' }, body: JSON.stringify(data) })
    const html = await response.text()
    await this.replaceFrameWithHtml(newFrame, html)
    SS.notice(i18next.t("ss.notice.saved"))
    dispatchEvent(this.targetElement(), "gws:column:added")
  }

  targetElement() {
    if (this._targetElement) {
      return this._targetElement
    }

    this._targetElement = document.querySelector(this.targetValue)
    return this._targetElement
  }

  addNewFrame() {
    return new Promise((resolve) => {
      const frame = document.createElement("div")
      frame.classList.add("gws-column-item")
      frame.classList.add("gws-column-item-new")
      frame.innerHTML = `<div class="main-box">${LOADING}</div>`

      const targetElement = this.targetElement()
      if (isPlacementTop(this.placementValue)) {
        targetElement.prepend(frame)
      } else {
        targetElement.append(frame)
      }

      requestAnimationFrame(() => resolve(frame))
    })
  }

  replaceFrameWithHtml(frame, html) {
    return new Promise((resolve) => {
      const templateElement = document.createElement("template")
      templateElement.innerHTML = html
      frame.replaceWith(templateElement.content)

      requestAnimationFrame(() => resolve())
    })
  }
}
