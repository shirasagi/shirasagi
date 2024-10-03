import { Controller } from "@hotwired/stimulus";
import {dispatchEvent} from "../../ss/tool";

export default class extends Controller {
  static values = { checked: String, unchecked: String };
  static targets = [ "source", "target" ];

  connect() {
    if (this.sourceTarget && this.targetTarget) {
      this.sourceTarget.addEventListener("change", (_ev) => this.#linkValue());
    }
    this.#linkValue();
  }

  #linkValue() {
    if (this.sourceTarget && this.targetTarget) {
      const newValue = this.sourceTarget.checked ? (this.checkedValue || this.sourceTarget.value) : (this.uncheckedValue || '');
      if (this.targetTarget.value !== newValue) {
        this.targetTarget.value = newValue;
        dispatchEvent(this.targetTarget, "ss:change");
      }
    }
  }
}
