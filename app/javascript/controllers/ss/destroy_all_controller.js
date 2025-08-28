import { Controller } from "@hotwired/stimulus"
import {
  csrfToken,
  showErrorInListItem
} from "../../ss/tool";
import i18next from "i18next";

export default class extends Controller {
  static values = {
    listSelector: { type: String, default: '.gws-tabular-views-main-box' },
    controllerIdentifier: { type: String, default: 'ss--list-action-enabler' }
  };

  connect() {
    // console.log(`[${this.identifier}] connected`, this.listSelectorValue, this.controllerIdentifierValue);
  }

  async destroyAll() {
    const checkedItems = this.#getCheckedItems();
    if (checkedItems.length === 0) {
      alert(i18next.t('helpers.select.prompt'))
      return;
    }

    if (!confirm(i18next.t('ss.confirm.delete'))) {
      return;
    }

    checkedItems.forEach((checkedListItem) => {
      checkedListItem.classList.add("busy");
      checkedListItem.querySelector("input:checked").disabled = true;
    });

    for (const checkedListItem of checkedItems) {
      await this.#destroyOne(checkedListItem);
    }

    checkedItems.forEach((checkedListItem) => {
      checkedListItem.classList.remove("busy");
      checkedListItem.querySelector("input:checked").disabled = false;
    });

    const otherController = this.#otherController;
    if (otherController) {
      otherController.updateAll();
    }
    SS.notice(i18next.t("ss.notice.deleted"));
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

  async #destroyOne(listItemElement) {
    const itemId = listItemElement.dataset.id;
    const response = await fetch(`${location.pathname}/${itemId}.json`, {
      method: 'DELETE',
      headers: { "X-CSRF-Token": csrfToken() }
    });

    if (response.ok) {
      listItemElement.remove();
      return;
    }

    let json;
    try {
      json = await response.json();
    } catch (_err) {
      json = undefined;
    }

    showErrorInListItem(listItemElement, response, json);
  }
}
