import { Controller } from "@hotwired/stimulus";
import {
  csrfToken,
  dispatchEvent,
  showErrorInListItem
} from "../../../ss/tool";
import i18next from "i18next";
import Dialog from "../../../ss/dialog";

export default class extends Controller {
  static targets = [ "dialog" ];
  static values = {
    listSelector: { type: String, default: '.gws-tabular-views-main-box' },
    controllerIdentifier: { type: String, default: 'ss--list-action-enabler' }
  };

  connect() {
    // console.log(`[${this.identifier}] connected`);
  }

  showDialog({ params: { href } }) {
    if (!this.hasDialogTarget) {
      return;
    }

    const checkedItems = this.#getCheckedItems();
    if (checkedItems.length === 0) {
      alert(i18next.t('helpers.select.prompt'));
      return;
    }

    Dialog.showModal(this.dialogTarget.cloneNode(true)).then((dialog) => {
      if (dialog.result === "approve" || dialog.result === "remand") {
        let comment = undefined;
        dialog.returnValue.forEach((value) => {
          if (value[0] === 'comment' && !comment) {
            comment = value[1];
          }
        });
        this.#approveAll(href, checkedItems, dialog.result, comment);
      }
    });
  }

  get #otherController() {
    const listElement = this.element.closest(this.listSelectorValue);
    if (!listElement) {
      return undefined;
    }

    return this.application.getControllerForElementAndIdentifier(
      listElement, this.controllerIdentifierValue);
  }

  #getCheckedItems() {
    const otherController = this.#otherController;
    if (!otherController) {
      return [];
    }

    return otherController.getCheckedItems();
  }

  async #approveAll(href, checkedItems, type, comment) {
    checkedItems.forEach((checkedItem) => {
      checkedItem.classList.add("busy");
      checkedItem.querySelector("input:checked").disabled = true;
    });

    for (const checkedItem of checkedItems) {
      await this.#approveOne(href, checkedItem, type, comment);
    }

    checkedItems.forEach((checkedItem) => {
      checkedItem.classList.remove("busy");
      checkedItem.querySelector("input:checked").disabled = false;
    });

    const otherController = this.#otherController;
    if (otherController) {
      otherController.updateAll();
    }
    dispatchEvent(this.element, `gws:tabular:${type}-all`)
  }

  async #approveOne(href, row, type, comment) {
    const path = href.replaceAll("$id", row.dataset.id);
    const body = {};
    body[type] = type;
    body["item"] = { comment };

    const response = await fetch(path, {
      method: 'PUT',
      headers: { "X-CSRF-Token": csrfToken(), 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });

    let json;
    try {
      json = await response.json();
    } catch (err) {
      json = undefined;
    }

    if (response.ok) {
      this.#showSuccess(row, response, json);
      return;
    }

    showErrorInListItem(row, response, json);
  }

  #showSuccess(row, response, json) {
    let ajaxResultElement = row.querySelector(".ss-ajax-result");
    if (ajaxResultElement) {
      ajaxResultElement.innerHTML = '';
      ajaxResultElement.classList.remove("hide");
    } else {
      ajaxResultElement = document.createElement("div");
      ajaxResultElement.classList.add("ss-ajax-result");
      row.appendChild(ajaxResultElement);
    }
    ajaxResultElement.classList.add("ss-ajax-success");
    ajaxResultElement.classList.remove("ss-ajax-failed");

    const successMark = document.createElement("span");
    successMark.classList.add("ss-ajax-success-icon");
    successMark.classList.add("material-icons-outlined");
    successMark.setAttribute("role", "image");
    successMark.setAttribute("aria-hidden", "true");
    successMark.textContent = "check_circle";
    ajaxResultElement.appendChild(successMark);

    const messageElement = document.createElement("span");
    messageElement.classList.add("ss-ajax-success-message");
    messageElement.textContent = json.notice || "proceeded";
    ajaxResultElement.appendChild(messageElement);
  }
}
