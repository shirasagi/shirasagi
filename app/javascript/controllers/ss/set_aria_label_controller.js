import { Controller } from "@hotwired/stimulus"
import i18next from 'i18next'

export default class extends Controller {
  connect() {
    this.setLabel(this.element);
    this.element.addEventListener("change", (ev) => this.setLabel(ev.target));
    //this.element.addEventListener("ss:checked-list-item", (ev) => this.setLabel(ev.target));
  }

  setLabel(el) {
    const name = el.dataset.name;
    const checked = el.checked;

    if (el.checked) {
      el.setAttribute("aria-label", i18next.t("ss.controls.close_checkbox", { name: name }));
    } else {
      el.setAttribute("aria-label", i18next.t("ss.controls.open_checkbox", { name: name }));
    }
  }
}
