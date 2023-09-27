import { Controller } from "@hotwired/stimulus"
import i18next from 'i18next'
import { LOADING, csrfToken, dispatchEvent } from "../../ss/tool"

const ERROR_TEMPLATE = `
  <div class="errorExplanation">
    <h2><%= template.header %></h2>
    <ul>
      <li><%= error.message %></li>
    </ul>
  </div>
`

export default class extends Controller {
  static values = { action: String, method: String, confirm: String };

  #overlayContainer = undefined;

  connect() {
    this.element.addEventListener("click", (ev) => {
      if (this.#doAction()) {
        ev.preventDefault();
        return false;
      }
    })
  }

  #doAction() {
    this.#clearAllOverlays();

    const listItems = this.#collectListItems();
    if (!listItems || listItems.length === 0) {
      alert(i18next.t("helpers.select.prompt"));
      return false;
    }

    if (this.confirmValue && !confirm(this.confirmValue)) {
      return false;
    }

    const promises = []
    listItems.forEach((listItem) => {
      this.#coverWithOverlay(listItem);

      const check = listItem.querySelector("input[name='ids[]']");
      const url = this.actionValue.replace(":id", encodeURIComponent(check.value));

      let method, body;
      switch (this.methodValue.toUpperCase()) {
        case 'GET':
          method = 'GET';
          body = undefined;
          break;
        case 'POST':
          method = 'POST';
          body = undefined;
          break;
        case 'PUT':
          method = "POST";
          body = new FormData();
          body.append('_method', 'PUT')
          break;
        case 'PATCH':
          method = "POST";
          body = new FormData();
          body.append('_method', 'PATCH')
          break;
        case 'DELETE':
          method = "POST";
          // body = `_method=DELETE`;
          body = new FormData();
          body.append('_method', 'DELETE')
          break;
      }

      const promise = fetch(url, {
        method: method,
        cache: "no-cache",
        headers: { "X-CSRF-Token": csrfToken() },
        body: body
      }).then((response) => this.#showResponse(listItem, response))
        .catch((_err) => this.#showError(listItem, { text: "Network Error" }));

      promises.push(promise);
    });

    Promise.all(promises).then(() => dispatchEvent(this.element, "ss:all-list-action-finished"));

    return true;
  }

  #collectListItems() {
    const ret = [];
    document.querySelectorAll(".list-item").forEach((listItem) => {
      const check = listItem.querySelector("input[name='ids[]']")
      if (check && check.checked) {
        ret.push(listItem);
      }
    })
    return ret;
  }

  #coverWithOverlay(listItem) {
    const overlay = this.#ensureHaveOverlay(listItem);

    const rect = listItem.getBoundingClientRect();
    overlay.style.top = `${rect.top + window.scrollY}px`;
    overlay.style.left = `${rect.left + window.scrollX}px`;
    overlay.style.width = `${rect.width}px`;
    overlay.style.height = `${rect.height}px`;
    overlay.style.alignItems = "center";
    overlay.innerHTML = `<div>${LOADING}</div>`;
    overlay.classList.remove("hide");
  }

  #ensureHaveOverlayContainer() {
    if (this.#overlayContainer) {
      return this.#overlayContainer;
    }

    const el = document.getElementById("ss-list-item-overlay-container");
    if (el) {
      this.#overlayContainer = el;
      return this.#overlayContainer;
    }

    const overlayContainer = document.createElement("div");
    overlayContainer.id = "ss-list-item-overlay-container";
    overlayContainer.classList.add("ss-list-item-overlay-container");
    document.body.appendChild(overlayContainer);

    this.#overlayContainer = overlayContainer;
    return this.#overlayContainer;
  }

  #ensureHaveOverlay(listItem) {
    this.#ensureHaveOverlayContainer();
    const el = this.#overlayContainer.querySelector(`[data-list-item-id="${listItem.dataset.id}"]`);
    if (el) {
      return el;
    }

    const overlay = document.createElement("div");
    overlay.classList.add("ss-list-item-overlay");
    overlay.classList.add("hide");
    overlay.dataset.listItemId = listItem.dataset.id;
    this.#overlayContainer.appendChild(overlay);

    return overlay;
  }

  #clearAllOverlays() {
    this.#ensureHaveOverlayContainer();
    this.#overlayContainer.innerHTML = '';
  }

  async #showResponse(listItem, response) {
    if (!response.ok) {
      const contentType = response.headers.get('content-type');
      if (!contentType || !contentType.includes('application/json')) {
        this.#showError(listItem, { text: "Server Error" })
        return;
      }

      this.#showError(listItem, { json: await response.json() })
      return;
    }

    const json = await response.json();
    this.#showSuccess(listItem, json)
  }

  #showSuccess(listItem, json) {
    const overlay = this.#ensureHaveOverlay(listItem);
    overlay.innerHTML = `<p>${json.title}</p>`

    const check = listItem.querySelector("input[name='ids[]']")
    if (check) {
      check.checked = false;
    }
  }

  #showError(listItem, error) {
    const overlay = this.#ensureHaveOverlay(listItem);

    let { text, json } = error;
    if (text) {
      overlay.innerHTML = `<p>${text}</p>`
    } else {
      overlay.innerHTML = ejs.render(
        ERROR_TEMPLATE,
        {
          template: {
            header: i18next.t("errors.template.header.one"),
            body: i18next.t("errors.template.body"),
          },
          error: {
            message: json.title
          }
        });
      overlay.style.alignItems = '';
    }
  }
}
