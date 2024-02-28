import { Controller } from "@hotwired/stimulus"
import i18next from 'i18next'

export default class extends Controller {
  connect() {
    // checkbox
    if (this.element.tagName.toLowerCase() == "input" && this.element.type == "checkbox") {
      this.connectCheckbox();
    }
    // tree_ui toogle
    if (this.element.tagName.toLowerCase() == "a" && this.element.classList && (this.element.classList.contains("closed") || this.element.classList.contains("opened"))) {
      this.connectToggle();
    }
  }

  connectCheckbox() {
    this.setCheckboxLabel(this.element);
    this.element.addEventListener("change", (ev) => this.setCheckboxLabel(ev.target));
  }

  setCheckboxLabel(element) {
    const name = element.dataset.name;
    const key1 = element.checked ? "close" : "open";
    const key2 = name ? "_of" : "";
    const label = i18next.t("ss.controls." + key1 + "_checkbox" + key2, { name: name });
    element.setAttribute("aria-label", label);
  }

  connectToggle() {
    this.setToggleLabel(this.element);
    this.element.addEventListener("change", (ev) => this.setToggleLabel(ev.target));
  }

  setToggleLabel(element) {
    const name = element.dataset.name;
    const key1 = element.classList.contains("opened") ? "close" : "open";
    const key2 = name ? "_of" : "";
    const label = i18next.t("ss.controls." + key1 + "_toggle" + key2, { name: name });
    element.setAttribute("aria-label", label);
    element.setAttribute("aria-expanded", element.classList.contains("opened"));
  }
}
