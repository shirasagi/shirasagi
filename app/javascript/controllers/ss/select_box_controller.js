import { Controller } from "@hotwired/stimulus"
import i18next from 'i18next'
import {dispatchEvent, appendChildren, replaceChildren} from "../../ss/tool"
import Dialog from "../../ss/dialog";
import ejs from 'ejs/ejs';

const DEFAULT_TEMPLATE = `
  <% if (selectedItems.length > 0) { %>
    <% selectedItems.forEach(function(selectedItem) { %>
      <tr data-id="<%= selectedItem.id %>">
        <td>
          <input type="attr.type" name="attr.name" value="<%= selectedItem.id %>" class="attr.class">
          <%= selectedItem.name %>
        </td>
        <td><button name="deselect" type="button" class="deselect btn"><%= label.delete %></button></td>
      </tr>
    <% }); %>
  <% } %>
`;

export default class extends Controller {
  static values = {
    api: String,
    dialogType: { type: String, default: "ss" },
    template: { type: String, default: "ejs" },
    selectionType: { type: String, default: "append" },
  }
  static targets = [ "result", "template", "ajaxTable" ]

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
    const apiUrl = new URL(this.apiValue, location.origin);
    this._selectedIds().forEach((id) => apiUrl.searchParams.append("selected[]", id));

    $.colorbox({
      fixed: true, open: true, href: apiUrl.toString(), width: "90%", height: "90%",
      onComplete: () => {
        const $ajaxBox = SS_SearchUI.anchorAjaxBox || $.colorbox.element();
        $ajaxBox.data('on-select', ($selectedItem) => {
          const $dataItem = $selectedItem.is("[data-id]") ? $selectedItem : $selectedItem.closest("[data-id]");
          const data = $dataItem[0].dataset;
          if (!data.name) {
            data.name = $dataItem.find(".select-item").text() || $selectedItem.text() || $dataItem.text();
          }
          selected.push(data);
        });
      },
      onCleanup: () => { this._renderResult(selected); $.colorbox.close(); }
    })
  }

  #openDialogBySS() {
    // not implemented yet.
    const apiUrl = new URL(this.apiValue, location.origin);
    this._selectedIds().forEach((id) => apiUrl.searchParams.append("selected[]", id));

    Dialog.showModal(apiUrl.toString()).then((result) => {
      this._renderResult(result.returnValue)
    })
  }

  #_templateSource = undefined;

  #templateSource() {
    if (this.#_templateSource) {
      return this.#_templateSource;
    }

    if (this.hasTemplateTarget) {
      this.#_templateSource = this.templateTarget.innerHTML;
      return this.#_templateSource;
    }

    const hiddenIdsElement = this.element.querySelector(".hidden-ids");
    if (hiddenIdsElement) {
      this.#_templateSource = DEFAULT_TEMPLATE.replaceAll("attr.name", hiddenIdsElement.name)
        .replaceAll("attr.type", hiddenIdsElement.type)
        .replaceAll("attr.class", hiddenIdsElement.getAttribute("class"));
      return this.#_templateSource;
    }

    this.#_templateSource = DEFAULT_TEMPLATE;
    return this.#_templateSource;
  }

  _renderResult(selectedItems) {
    if (!this.hasResultTarget) {
      return;
    }

    if (this.selectionTypeValue === "replace") {
      const result = ejs.render(
        this.#templateSource(),
        {
          selectedItems: selectedItems,
          label: { delete: i18next.t("ss.buttons.delete") }
        }
      )

      replaceChildren(this.resultTarget, result);
    } else {
      // append only missing items
      const existedIds = this._selectedIds();
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

    if (this.hasAjaxTableTarget) {
      const $table = $(this.ajaxTableTarget);
      if ($table.find("tbody tr").size() === 0) {
        $table.hide();
      } else {
        $table.show();
      }
      $table.trigger("change");
    }
  }

  _selectedIds() {
    if (!this.resultTarget) {
      return;
    }

    const ids = Array.from(this.resultTarget.querySelectorAll("[data-id]")).map((element) => element.dataset.id);
    return new Set(ids);
  }
}
