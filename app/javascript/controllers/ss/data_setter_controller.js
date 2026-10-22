import { Controller } from "@hotwired/stimulus"
import { csrfToken } from "../../ss/tool";

export default class extends Controller {
  static values = {
    attributeName: String,
  }

  connect() {
    console.log(`[${this.identifier}] connected`);
  }

  set(ev) {
    if (!this.hasAttributeNameValue) {
      console.info(`provide attributeName to set via data-${this.identifier}-attribute-name-value`)
      return;
    }

    let value = ev.currentTarget.dataset.attributeValue;
    value ||= ev.currentTarget.value;
    console.log({ value });
    this.element.dataset[this.attributeNameValue] = value;
  }
}
