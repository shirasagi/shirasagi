import { Controller } from "@hotwired/stimulus"
import ejs from "ejs/ejs";
import {appendChildren, csrfToken, dispatchEvent} from "../../ss/tool";

export default class extends Controller {
  static values = {
    previewApi: String,
  }
  static targets = [ "realButton", "dummyButton", "template", "result", "resultItem" ];

  connect() {
    if (this.hasRealButtonTarget) {
      this.realButtonTarget.addEventListener('change', () => this.#selectFiles())
    }
  }

  openDialog() {
    if (!this.hasRealButtonTarget) {
      return;
    }

    this.realButtonTarget.click();
  }

  deselect(ev) {
    if (!this.hasResultItemTarget) {
      return;
    }

    let removed = false;
    this.resultItemTargets.forEach((resultItem) => {
      if (resultItem.contains(ev.target)) {
        removed = this.resultTarget.contains(resultItem);
        resultItem.remove();
      }
    })

    if (removed) {
      dispatchEvent(this.resultTarget, "change");
    }
  }

  select(ev) {
    ev.preventDefault();
    dispatchEvent(ev.target, "ss:modal-select", { item: $(ev.target) });
    dispatchEvent(ev.target, "ss:modal-close");
  }

  async #selectFiles() {
    if (this.hasDummyButtonTarget) {
      this.dummyButtonTarget.disabled = true;
    }

    const templateSource = this.templateTarget.innerHTML;

    const renderOne = async (file) => {
      const formData = new FormData();
      formData.append("item[files][][name]", file.name);
      formData.append("item[files][][size]", file.size);
      formData.append("item[files][][content_type]", file.type);

      const response = await fetch(this.previewApiValue, {
        method: "POST",
        headers: { "X-CSRF-Token": csrfToken() },
        body: formData
      });
      const json = await response.json();

      const result = ejs.render(templateSource, { selectedItems: json })
      appendChildren(this.resultTarget, result);
    };

    for (const file of this.realButtonTarget.files) {
      await renderOne(file);
    }

    this.realButtonTarget.files = undefined;
    if (this.hasDummyButtonTarget) {
      this.dummyButtonTarget.disabled = false;
    }

    dispatchEvent(this.resultTarget, "change");
  }
}
