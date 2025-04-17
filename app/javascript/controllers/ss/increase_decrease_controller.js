import { Controller } from "@hotwired/stimulus"
import {appendAfter, appendChildren} from "../../ss/tool";

export default class extends Controller {
  static values = {
    attribute: String,
    max: Number,
  };
  static targets = [
    "container",
    "template",
    "item"
  ];

  connect() {
  }

  increase(ev) {
    if (!this.hasTemplateTarget) {
      return;
    }

    const itemElement = ev.currentTarget.closest(`[data-ss--increase-decrease-target="item"]`);
    if (!itemElement) {
      // out of scope
      return;
    }

    if (this.hasMaxValue) {
      const currentItemCount = this.itemTargets.length
      if (currentItemCount + 1 > this.maxValue) {
        const message = i18next.t("errors.messages.too_large", { count: this.maxValue });
        const fullMessages = i18next.t("errors.format", { attribute: this.attributeValue, message: message });
        alert(fullMessages);
        return;
      }
    }

    appendAfter(itemElement, this.templateTarget);
  }

  decrease(ev) {
    const itemElement = ev.currentTarget.closest(`[data-ss--increase-decrease-target="item"]`);
    if (!itemElement) {
      // out of scope
      return;
    }

    itemElement.remove();
  }
}
