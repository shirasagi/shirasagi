import { Controller } from "@hotwired/stimulus"
import Dialog from "../../ss/dialog";

export default class extends Controller {
  static targets = [ "content" ]
  static values = { open: Boolean, attach: Boolean }

  dialog = undefined;

  connect() {
    const dialogSource = this.hasContentTarget ? this.contentTarget : this.element
    this.dialog = new Dialog(dialogSource, { attach: this.attachValue, source: this.element });
    if (this.openValue) {
      this.open();
    }
  }

  open(ev) {
    if (!this.dialog) {
      return;
    }
    if (ev?.currentTarget) {
      this.dialog.options.source = ev.currentTarget
    } else {
      this.dialog.options.source = this.element
    }
    this.dialog.showModal().then((result) => this.apply(result));
  }

  apply(_dialog) {
    this.dialog.options.source = this.element
  }
}
