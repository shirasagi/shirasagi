import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.currentNodeId = this.element.dataset.currentNodeId
    this.element.addEventListener("turbo:frame-load", () => this.highlightAndOpenFolders());
  }

  highlightAndOpenFolders() {
    this.clearHighlights();
    if (!this.currentNodeId) {
      return;
    }

    this.element.querySelectorAll(`[data-node-id="${this.currentNodeId}"]`).forEach((el) => {
      const treeItemElement = el.closest(".ss-tree-item")
      if (treeItemElement) {
        treeItemElement.classList.add("is-current");
      }

      const detailsElement = el.closest(".ss-tree-subtree-wrap")
      if (detailsElement) {
        this.openAllParents(detailsElement);
      }
    });
  }

  openAllParents(element) {
    let parent = element;
    while (parent) {
      parent.open = true;
      parent = parent.parentElement.closest(".ss-tree-subtree-wrap");
    }
  }

  clearHighlights() {
    this.element.querySelectorAll(".is-current").forEach((el) => {
      el.classList.remove("is-current")
    });
  }
}
