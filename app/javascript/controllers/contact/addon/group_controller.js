import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  initialize() {
  }

  connect() {
    const $table = $(this.element).find(".contact-groups-table");
    if ($table[0]) {
      this.bind();
    }
  }

  disconnect() {
  }

  bind() {
    this.element.addEventListener("click", (ev) => {
      if (ev.target.classList.contains("btn-add")) {
        this.addRow(ev)
      }
      if (ev.target.classList.contains("btn-delete")) {
        this.deleteRow(ev)
      }
      if (ev.target.classList.contains("unifies-to-main")) {
        this.toggleUnfiesToMain(ev)
      }
    })

    this.element.querySelectorAll("[data-id]").forEach((listItem) => {
      const countElement = listItem.querySelector(".pages-used [data-count]")
      if (countElement && countElement.dataset.count && countElement.dataset.count === "0") {
        const deleteBtn = listItem.querySelector(".operations .btn-delete")
        if (deleteBtn) {
          deleteBtn.disabled = false
        }
      }

      const mainStateElement = listItem.querySelector('[name="item[destinations][][contact_groups][][main_state]"]')
      if (mainStateElement.value === "main") {
        const unifiesToMainEl = this.element.querySelector(".unifies-to-main");
        if (unifiesToMainEl) {
          const initialUnifiesToMainValue = listItem.querySelector('[name="item[destinations][][contact_groups][][unifies_to_main]"]').value;
          unifiesToMainEl.checked = (initialUnifiesToMainValue === "enabled");
        }
      }
    })
  }

  addRow(_ev) {
    const template = this.element.querySelector("#new-contact-group-row")
    const $newRow = $(template.innerHTML)

    const unifiesToMainEl = this.element.querySelector(".unifies-to-main");
    if (unifiesToMainEl) {
      const value = unifiesToMainEl.checked ? "enabled" : "disabled";
      $newRow.find('[name="item[destinations][][contact_groups][][unifies_to_main]"]').val(value);
    }

    const $table = $(this.element).find(".contact-groups-table")
    $table.find("tbody").append($newRow)
  }

  deleteRow(ev) {
    const $tr = $(ev.target).closest("tr")
    if ($tr.data("id") !== "new") {
      $tr.remove()
      return
    }

    if ($tr.closest("table").find("[data-id='new']").length > 1) {
      $tr.remove()
    }
  }

  toggleUnfiesToMain(ev) {
    const value = ev.target.checked ? "enabled" : "disabled"
    this.element.querySelectorAll('[name="item[destinations][][contact_groups][][unifies_to_main]"]').forEach((unifiesToMainEl) => {
      unifiesToMainEl.value = value
    })
  }
}
