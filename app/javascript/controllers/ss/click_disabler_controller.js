import { Controller } from "@hotwired/stimulus"

function clickableInput(element) {
  const tagName = element.tagName.toLowerCase()
  if (tagName !== "input") {
    return false
  }

  const type = element.type.toLowerCase()
  return type === "submit" || type === "button"
}

export default class extends Controller {
  connect() {
    // クリックを無効化するために capture フェーズでイベントを補足
    this.element.addEventListener("click", (ev) => { return this.#cancelClick(ev) }, { capture: true })
  }

  #cancelClick(ev) {
    const tagName = ev.target.tagName.toLowerCase()
    if (tagName !== "a" && tagName !== "button" && !clickableInput(ev.target)) {
      return true
    }

    // data-except="true" が指定されている場合、クリックを実行させる。
    if (ev.target.dataset.except) {
      return true
    }

    // クリック無効化
    ev.stopPropagation()
    ev.preventDefault()
    return false
  }
}
