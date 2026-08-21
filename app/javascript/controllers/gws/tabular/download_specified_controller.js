import { Controller } from "@hotwired/stimulus"
import {
  csrfToken
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
    // console.log(`[${this.identifier}] connected`, this.listSelectorValue, this.controllerIdentifierValue);
  }

  async downloadAll({ params: { href } }) {
    const checkedItems = this.#getCheckedItems();
    if (checkedItems.length === 0) {
      alert(i18next.t('helpers.select.prompt'))
      return;
    }

    const checkedItemIds = [];
    checkedItems.forEach((checkedItem) => {
      const itemId = checkedItem.dataset.id;
      if (itemId) {
        checkedItemIds.push(itemId);
      }
    });
    if (checkedItemIds.length === 0) {
      alert(i18next.t('helpers.select.prompt'))
      return;
    }

    Dialog.showModal(this.dialogTarget.cloneNode(true)).then((dialogResult) => {
      if (dialogResult.returnValue === "download") {
        const form = this.#buildForm(href, checkedItemIds, dialogResult.formData);
        document.body.appendChild(form);
        form.requestSubmit();

        const otherController = this.#otherController;
        if (otherController) {
          otherController.updateAll();
        }
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

  #buildForm(href, ids, formData) {
    const form = document.createElement("form");
    form.action = href;
    form.method = "post";
    // form.target = "_blank";

    const inputAuthneticityToken = document.createElement("input");
    inputAuthneticityToken.type = "hidden";
    inputAuthneticityToken.name = "authneticity_token";
    inputAuthneticityToken.value = csrfToken();
    form.appendChild(inputAuthneticityToken);

    const inputMethod = document.createElement("input");
    inputMethod.type = "hidden";
    inputMethod.name = "_method";
    inputMethod.value = "put";
    form.appendChild(inputMethod);

    ids.forEach((id) => {
      const inputId = document.createElement("input");
      inputId.type = "hidden";
      inputId.name = "item[ids][]";
      inputId.value = id;
      form.appendChild(inputId);
    });

    if (formData) {
      for (const [ key, value ] of formData.entries()) {
        const inputParam = document.createElement("input");
        inputParam.type = "hidden";
        inputParam.name = key;
        inputParam.value = value;
        form.appendChild(inputParam);
      }
    }

    return form
  }
}
