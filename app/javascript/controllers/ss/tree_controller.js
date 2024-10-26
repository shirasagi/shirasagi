import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["details", "li"];

  connect() {
    this.highlightAndOpenFolders();
  }

  highlightAndOpenFolders() {
    const currentPath = location.pathname;
    const currentNumber = this.extractNumber(currentPath);

    this.detailsTargets.forEach(details => {
      const anchor = details.querySelector("summary a");
      const href = anchor.getAttribute("href");

      if (this.isPathMatch(currentNumber, href)) {
        details.open = true;
        details.querySelector("summary").classList.add("highlight");
        this.openAllParents(details);
      }
    });

    this.liTargets.forEach(li => {
      const anchor = li.querySelector("a");
      const href = anchor.getAttribute("href");

      if (this.isPathMatch(currentNumber, href)) {
        li.classList.add("highlight");
        this.openAllParents(li.closest("details"));
      }

      anchor.addEventListener("click", (event) => {
        event.preventDefault();
        this.clearHighlights();
        li.classList.add("highlight");
        this.openAllParents(li.closest("details"));
        window.location.href = href;
      });
    });
  }

  openAllParents(element) {
    let parent = element.closest("details");
    while (parent) {
      parent.open = true;
      parent = parent.parentElement.closest("details");
    }
  }

  extractNumber(path) {
    const match = path.match(/(\d+)(?=[^0-9]*$)/);
    return match ? match[1] : null;
  }

  isPathMatch(currentNumber, href) {
    const match = href.match(/(\d+)(?=[^0-9]*$)/);
    const hrefNumber = match ? match[1] : null;

    if (location.pathname === "/.s1/cms/nodes") {
      return false;
    }

    return currentNumber === hrefNumber;
  }

  toggle(event) {
    const details = event.currentTarget.closest("details");

    if (event.target.closest('a')) {
      return; 
    }

    details.open = !details.open;
    event.preventDefault();
  }

  clearHighlights() {
    this.detailsTargets.forEach(details => {
      details.querySelector("summary")?.classList.remove("highlight");
    });
    this.liTargets.forEach(li => li.classList.remove("highlight"));
  }
}
