import { Controller } from "@hotwired/stimulus"
import "./more_content.scss"

export default class extends Controller {
  static targets = [ "body", "bottom" ];

  #resizeObserver = undefined;

  connect() {
    // console.log(`[${this.identifier}] connected`);
    if (!this.#resizeObserver) {
      this.#resizeObserver = new ResizeObserver((entries) => this.#onResize(entries));
      this.#resizeObserver.observe(this.bottomTarget);
    }
  }

  disconnect() {
    this.#resizeObserver.disconnect();
    // console.log(`[${this.identifier}] disconnected`);
  }

  expandAll(_ev) {
    // console.log(`[${this.identifier}] expandAll`);
    this.element.dataset.isOpen = true;
  }

  #onResize(resizeObserverEntries) {
    // console.log(`[${this.identifier}] onResize`, resizeObserverEntries);
    const entry = resizeObserverEntries[0];
    const expanded = this.element.dataset.isOpen || (entry.contentRect.height === 0);
    // console.log({ expanded: expanded });
    this.bodyTarget.ariaExpanded = expanded;
    this.bottomTarget.querySelectorAll("[data-action]").forEach((element) => element.disabled = expanded);
  }
}
