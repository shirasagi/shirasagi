import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  initialize() {
  }

  connect() {
    const $table = $(this.element).find(".contact-groups-table");
    if ($table[0]) {
      SS.ready(() => {
        this.table = $table.DataTable({
          info: false, ordering: false, paging: false, scrollX: true, searching: false
        });
      })
    }

    this.bind();
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

  addRow(ev) {
    const template = this.element.querySelector("#new-contact-group-row")
    const $newRow = $(template.innerHTML)

    const $table = $(this.element).find(".contact-groups-table")
    $table.find("tbody").append($newRow)

    // const $tr = $(ev.currentTarget).closest("tr")
    // $tr.before($newRow)
  }

  deleteRow(ev) {
    const $tr = $(ev.currentTarget).closest("tr")
    if ($tr.data("id") !== "new") {
      $tr.remove()
    }
  }
}
