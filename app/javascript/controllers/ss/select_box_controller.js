import { Controller } from "@hotwired/stimulus"
import i18next from 'i18next'
import {dispatchEvent, appendChildren} from "../../ss/tool"
import Dialog from "../../ss/dialog";
import ejs from 'ejs/ejs';

const DEFAULT_TEMPLATE = `
  <tr data-id="<%= data.id %>">
    <td>
      <input type="<%= attr.type %>" name="<%= attr.name %>" value="<%= data.id %>" class="<%= attr.class %>">
      <%= data.name %>
    </td>
    <td><a class="deselect btn" href="#"><%= label.delete %></a></td>
  </tr>
`;

export default class extends Controller {
  static values = { api: String, dialogType: { type: String, default: "ss" }, template: { type: String, default: "ejs" } }
  static targets = [ "result", "template" ]

  connect() {
  }

  openDialog() {
    if (!this.apiValue) {
      return;
    }

    if (this.dialogTypeValue === "cbox") {
      this.#openDialogByCBox();
    } else {
      this.#openDialogBySS();
    }

    dispatchEvent(this.element, "change");
  }

  deselectItem(ev) {
    const itemElement = ev.target.closest("[data-id]")
    if (itemElement) {
      itemElement.remove();
    }
  }

  #openDialogByCBox() {
    const selected = [];
    const params = new URLSearchParams();
    this.#selectedIds().forEach((id) => params.append("selected[]", id));

    $.colorbox({
      fixed: true, open: true, href: this.apiValue + "?" + params.toString(), width: "90%", height: "90%",
      onComplete: () => {
        const $ajaxBox = SS_SearchUI.anchorAjaxBox || $.colorbox.element();
        $ajaxBox.data('on-select', ($selectedItem) => {
          const $dataItem = $selectedItem.closest("[data-id]");
          const data = $dataItem[0].dataset;
          if (!data.name) {
            data.name = $dataItem.find(".select-item").text() || $selectedItem.text() || $dataItem.text();
          }
          selected.push(data);
        });
      },
      onCleanup: () => { this.#renderResult(selected); }
    })
  }

  #openDialogBySS() {
    // not implemented yet.
    Dialog.showModal(this.apiValue).then((result) => {
      console.log(result);
    })
  }

  #templateSource() {
    if (this.templateTarget) {
      return this.templateTarget.innerHTML;
    }

    return DEFAULT_TEMPLATE;
  }

  #renderResult(selectedItems) {
    if (!this.resultTarget) {
      return;
    }

    const existedIds = this.#selectedIds();
    const nonExistedItems = selectedItems.filter((selectedItem) => !existedIds.has(selectedItem.id))

    const result = ejs.render(
      this.#templateSource(),
      {
        selectedItems: nonExistedItems,
        label: { delete: i18next.t("ss.buttons.delete") }
      }
    )

    appendChildren(this.resultTarget, result);
  }

  #selectedIds() {
    if (!this.resultTarget) {
      return;
    }

    const ids = Array.from(this.resultTarget.querySelectorAll("[data-id]")).map((element) => element.dataset.id);
    return new Set(ids);
  }
}
