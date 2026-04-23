import { Controller } from "@hotwired/stimulus"

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
      checkBox.checked = state;
    });
  }
}
