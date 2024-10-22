import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["details"];

  connect() {
    this.detailsTargets.forEach(details => {
      const shouldBeOpen = details.dataset.open === "true";
      if (shouldBeOpen) {
        details.open = true;
      }

      const summary = details.querySelector("summary");
      const shouldBeHighlighted = summary.dataset.highlight === "true";
      if (shouldBeHighlighted) {
        summary.classList.add("highlight");
      }
    });


    this.element.querySelectorAll("li[data-highlight]").forEach(li => {
      const shouldBeHighlighted = li.dataset.highlight === "true";
      if (shouldBeHighlighted) {
        li.classList.add("highlight");
      }
    });
  }

  toggle(event) {
    const details = event.currentTarget.closest("details");
 
    if (event.target.closest('a')) {
      return; 
    }

    if (details.open) {
      details.open = false;
    } else {
      details.open = true;
    }
    event.preventDefault();
  }
}
