import { Controller } from "@hotwired/stimulus"
import { dispatchEvent } from "../../ss/tool";

export default class extends Controller {
  checkAll() {
    this.#modifyCheckBoxAll(true);
  }

  uncheckAll() {
    this.#modifyCheckBoxAll(false);
  }

  #modifyCheckBoxAll(state) {
    var checkboxes = this.element.querySelectorAll('input[type=checkbox]');
    checkboxes.forEach((checkBox) => {
      if (checkBox.checked !== state) {
        checkBox.checked = state;
        dispatchEvent(checkBox, "change");
      }
    });
  }
}
