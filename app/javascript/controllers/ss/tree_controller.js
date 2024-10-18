import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["details"];

  connect() {
  }

  toggle(event) {
    const details = event.currentTarget.closest("details");

    if (details.open) {
      details.open = false;  
    } else {
      details.open = true;
    }
    event.preventDefault();
  }
}