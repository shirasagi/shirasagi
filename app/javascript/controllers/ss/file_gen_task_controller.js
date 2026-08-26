import { Controller } from "@hotwired/stimulus";
import { dispatchEvent } from "../../ss/tool";

export default class extends Controller {
  static values = {
    timer: { type: Number, default: 3000 }
  }
  static targets = [ "refresh", "autoRefresh", "instantlyClickAndClose" ]

  connect() {
    console.log(`[${this.identifier}] connected`)
    this._intervalId = setInterval((ev) => this.#onInterval(ev), this.timerValue)
  }

  disconnect() {
    if (this._intervalId) {
      clearInterval(this._intervalId)
    }
    super.disconnect()
    console.log(`[${this.identifier}] disconnected`)
  }

  instantlyClickAndCloseTargetConnected(element) {
    element.click()
    dispatchEvent(this.element, "ss:modal-close")
  }

  #onInterval(_ev) {
    if (this.hasAutoRefreshTarget && !this.autoRefreshTarget.checked) {
      // console.log(`[${this.identifier}] auto refresh is disabled`)
      return
    }
    if (! this.hasRefreshTarget) {
      return
    }
    this.refreshTargets.forEach((el) => el.click())
  }
}
