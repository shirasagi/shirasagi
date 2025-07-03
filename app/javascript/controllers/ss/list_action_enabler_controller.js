import { Controller } from "@hotwired/stimulus"
import {CHECKED_LIST_ITEM_SELECTOR, LIST_ITEM_SELECTOR} from "../../ss/tool";

export default class extends Controller {
  static targets = [ "button" ]

  connect() {
    const $element = $(this.element);
    $element.on("ss:checked-all-list-items", (_ev) => {
      this.updateAll();
    });
    $element.on("change", LIST_ITEM_SELECTOR, (_ev) => {
      this.updateAll();
    })
    // console.log(`[${this.identifier}] connected`);
  }

  getCheckedItems() {
    return this.element.querySelectorAll(CHECKED_LIST_ITEM_SELECTOR);
  }

  updateAll() {
    if (!this.hasButtonTarget) {
      return;
    }

    const checkedCount = this.getCheckedItems().length;
    this.buttonTargets.forEach((buttonTarget) => {
      buttonTarget.disabled = (checkedCount === 0);

      const badgeElement = buttonTarget.querySelector(".badge");
      if (badgeElement) {
        badgeElement.textContent = checkedCount.toString();
        badgeElement.dataset.count = checkedCount.toString();
      }
    });
  }
}
