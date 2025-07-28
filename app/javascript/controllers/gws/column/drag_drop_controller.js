import { Controller } from "@hotwired/stimulus"
import { smoothDnD } from 'smooth-dnd';
import i18next from 'i18next'
import { csrfToken } from "../../../ss/tool"

export default class extends Controller {
  static values = {
    reorder: String
  }

  connect() {
    this.element.addEventListener("gws:column:added", () => this.#restartSmoothDnD())
    this.#restartSmoothDnD()
  }

  #restartSmoothDnD() {
    if (this.sdnd) {
      this.sdnd.dispose()
      this.sdnd = null

      requestAnimationFrame(() => this.#restartSmoothDnD())
      return
    }

    if (this.element.childElementCount > 0) {
      this.sdnd = smoothDnD(this.element, {
        lockAxis: "y", dragHandleSelector: ".gws-column-item-drag-handle",
        onDrop: (dropResult) => this.#finalizeDrop(dropResult)
      })
    }
  }

  async #finalizeDrop(_dropResult) {
    if (!this.reorderValue) {
      return
    }

    const ids = [];
    Array.from(this.element.querySelectorAll(".gws-column-item")).forEach((item) => { ids.push(item.dataset.id) })

    const response = await fetch(this.reorderValue, {
      method: 'POST',
      headers: { "X-CSRF-Token": csrfToken(), 'Content-Type': 'application/json' },
      body: JSON.stringify({ ids: ids })
    })

    const json = await response.json();
    if (json && json.error) {
      alert(json.error)
      return
    }

    SS.notice(i18next.t("gws/column.notice.reordered"))
  }
}
