import { Controller } from "@hotwired/stimulus"
import i18next from 'i18next'
import Dialog from "../../../ss/dialog"
import {csrfToken, dispatchEvent, fadeOut} from "../../../ss/tool"

function findItemRoot(element) {
  while (element.parentElement) {
    if (element.parentElement.classList.contains("gws-column-item-list")) {
      break
    }

    element = element.parentElement
  }
  return element
}

export default class extends Controller {
  connect() {
    this.element.addEventListener("click", (ev) => {
      if (ev.target.classList.contains("btn-gws-column-item-delete") || ev.target.closest(".btn-gws-column-item-delete"))  {
        this.#removeColumnItem(ev)
        ev.stopImmediatePropagation()
        ev.preventDefault()
        return false
      }
      if (ev.target.classList.contains("btn-gws-column-item-detail") || ev.target.closest(".btn-gws-column-item-detail")) {
        this.#showColumnDetail(ev)
        ev.stopImmediatePropagation()
        ev.preventDefault()
        return false
      }

      return true
    })
  }

  #showColumnDetail(ev) {
    const btn = ev.target.classList.contains("btn-gws-column-item-detail") ? ev.target : ev.target.closest(".btn-gws-column-item-detail")
    if (btn.dataset.ref) {
      Dialog.showModal(btn.dataset.ref)
    }
  }

  async #removeColumnItem(ev) {
    const btn = ev.target.classList.contains("btn-gws-column-item-delete") ? ev.target : ev.target.closest(".btn-gws-column-item-delete")
    if (!btn.dataset.ref) {
      return
    }

    if (!confirm(i18next.t("ss.confirm.delete"))) {
      return
    }

    const response = await fetch(btn.dataset.ref, {
      method: 'DELETE',
      headers: { "X-CSRF-Token": csrfToken() }
    })

    const contentType = response.headers.get("Content-Type")
    if (!contentType.includes("application/json")) {
      return
    }

    const json = await response.json()
    if (json.error) {
      alert(json.error)
      return
    }

    const columnItemList = this.element.closest(".gws-column-item-list")
    const columnItem = findItemRoot(this.element)
    if (!columnItem) {
      return
    }

    SS.notice(json.notice || i18next.t("ss.notice.deleted"))
    await fadeOut(columnItem)

    columnItem.remove()
    if (columnItemList) {
      dispatchEvent(columnItemList, "gws:column:removed")
    }
  }
}
