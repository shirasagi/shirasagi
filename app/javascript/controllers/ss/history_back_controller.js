import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("click", (ev) => {
      this.historyBack();
      ev.preventDefault();
      return false;
    });
  }

  historyBack() {
    history.back();
  }
}
