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

        // .DataTable を実行すると HTML 構造が変わるので実行後に event をバインドする
        setTimeout(() => this.bind(), 0)
      })
    }
  }

  disconnect() {
  }

  bind() {
    const $table = $(this.element).find(".contact-groups-table");
    $table.on("click", ".btn-add", (ev) => this.addRow(ev))
    $table.on("click", ".btn-delete", (ev) => this.deleteRow(ev))
  }

  addRow(ev) {
    const $tr = $(ev.currentTarget).closest("tr")
    const $newRow = $($tr.prop("outerHTML"))
    $newRow.removeClass("even")
    $newRow.removeClass("odd")
    $newRow.attr("data-id", "")

    $tr.before($newRow)
  }

  deleteRow(ev) {
    const $tr = $(ev.currentTarget).closest("tr")
    if ($tr.data("id") !== "new") {
      $tr.remove()
    }
  }
}
