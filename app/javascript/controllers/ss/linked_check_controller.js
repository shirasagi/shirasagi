import { Controller } from "@hotwired/stimulus";
import {dispatchEvent} from "../../ss/tool";

const connected = new Set();

export default class extends Controller {
  static values = { checked: String, unchecked: String };
  static targets = [ "source", "target" ];

  connect() {
    if (connected.has(this.element)) {
      return;
    }

    connected.add(this.element);
    if (this.sourceTarget && this.targetTarget) {
      this.sourceTargets.forEach((sourceTarget) => {
        sourceTarget.addEventListener("change", (ev) => this.#linkValue(ev.target));
      })

      const checkedSourceTarget = this.sourceTargets.find((sourceTarget) => sourceTarget.checked)
      this.#linkValue(checkedSourceTarget || this.sourceTargets[0]);
    }
  }

  disconnect() {
    connected.delete(this.element);
  }

  #linkValue(sourceTarget) {
    if (this.targetTarget) {
      const newValue = sourceTarget.checked ? (this.checkedValue || sourceTarget.value) : (this.uncheckedValue || '');
      if (this.targetTarget.value !== newValue) {
        this.targetTarget.value = newValue;
        dispatchEvent(this.targetTarget, "ss:change");
      }
    }
  }
}
