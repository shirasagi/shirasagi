import { Controller } from "@hotwired/stimulus"
import i18next from 'i18next'
import {csrfToken} from "../../ss/tool"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.element.addEventListener("blur", this.handleBlur.bind(this), true);
  }

  handleBlur(event) {
    const input = event.target;
    if (input.tagName.toLowerCase() === "input") {
      const row = input.closest("tr");
      const id = row.dataset.id;
      const in_updated = row.dataset.updated;
      const field = input.name;
      const value = input.value;
      const data = { id: id, in_updated: in_updated };
      data[field] = value;
      fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken(),
        },
        body: JSON.stringify(data),
      })
        .then(response => response.json())
        .then(data => {
          if (data.success) {
            row.querySelector("td:last-child").innerText = i18next.t("ss.notice.saved");
            row.dataset.updated = data.updated;
          } else {
            row.querySelector("td:last-child").innerText = data.error;
          }
        })
        .catch(() => {
          row.querySelector("td:last-child").innerText = i18next.t("ss.notice.not_saved_successfully");
        });
    }
  }
}
