import { Controller } from "@hotwired/stimulus"
import Dialog from "../../../ss/dialog";

export default class extends Controller {
  static values = {
    baseUrl: String
  }

  connect() {
    const templateElement = this.element.querySelector(".gws-category-navi-dialog-template")
    if (!templateElement) {
      return;
    }

    this.element.addEventListener("click", (ev) => {
      if (ev.target.closest('.btn-category')) {
        Dialog.showModal(templateElement).then((result) => this.#apply(result))
      }
    })
  }

  #apply(dialog) {
    if (!dialog.returnValue) {
      // dialog is just closed
      return;
    }

    const categoryIds = []
    dialog.returnValue.forEach((value) => {
      if (value[0] === 's[category_ids][]') {
        categoryIds.push(value[1])
      }
    })

    const id = (categoryIds.length > 0) ? categoryIds.join(",") : '-'
    location.href = this.baseUrlValue.replace('ID', id)
  }
}
