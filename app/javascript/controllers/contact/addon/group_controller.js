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
    })
  }

  addRow(_ev) {
    const template = this.element.querySelector("#new-contact-group-row")
    const $newRow = $(template.innerHTML)

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
}
