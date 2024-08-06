import { Controller } from "@hotwired/stimulus"
import Dialog from "../../ss/dialog";

export default class extends Controller {
  static targets = [ "content" ]
  static values = { open: Boolean, attach: Boolean }

  dialog = undefined;

  connect() {
    this.dialog = new Dialog(this.hasContentTarget ? this.contentTarget : this.element, { attach: this.attachValue });
    if (this.openValue) {
      this.open();
    }
  }

  open() {
    if (!this.dialog) {
      return;
    }
    this.dialog.showModal().then((result) => this.apply(result));
  }

  apply(_dialog) {
  }
}
