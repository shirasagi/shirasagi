import { Controller } from "@hotwired/stimulus"

const EMPTY_OPTION = "<option value=\"\" label=\" \"></option>";

export default class extends Controller {
  static targets = [ "source", "target" ];
  static values = { url: String };

  originalSelectedValue = undefined;

  connect() {
    if (this.sourceTarget) {
      this.sourceTarget.addEventListener("change", () => this.#changeTarget());
    }
    if (this.targetTarget) {
      this.originalSelectedValue = this.targetTarget.value;
      this.#changeTarget();
    }
  }

  async #changeTarget() {
    if (!this.targetTarget) {
      return;
    }
    if (!this.urlValue) {
      return;
    }

    if (this.sourceTarget.value) {
      const params = new URLSearchParams();
      params.append("item[column_id]", this.sourceTarget.value);

      const response = await fetch(this.urlValue + "?" + params.toString())
      if (!response.ok) {
        this.targetTarget.innerHTML = EMPTY_OPTION;
        this.targetTarget.disabled = true;
        this.targetTarget.dataset.error = response.status;
        return;
      }

      this.targetTarget.innerHTML = await response.text();
      this.targetTarget.disabled = false;
      delete this.targetTarget.dataset.error;
      if (this.originalSelectedValue) {
        const optionElement = this.targetTarget.querySelector(`option[value="${this.originalSelectedValue}"]`);
        if (optionElement) {
          optionElement.selected = true;
        }
      }
    } else {
      this.targetTarget.innerHTML = EMPTY_OPTION;
      this.targetTarget.disabled = true;
      delete this.targetTarget.dataset.error;
    }
  }
}
