import { Controller } from "@hotwired/stimulus";
import ejs from "ejs/ejs";
import {prependChildren, csrfToken, dispatchEvent, LOADING} from "../../ss/tool";
import i18next from 'i18next';
import DropArea from "../../ss/drop_area";

const NUM_RETRY = 5;

function createError(errors, options) {
  // <div id="errorExplanation" class="errorExplanation">
  //   <h2>登録内容を確認してください。</h2>
  //   <p>次の項目を確認してください。</p>
  //   <ul>
  //     <li>ファイル名を入力してください。</li>
  //     <li>タイトルを入力してください。</li>
  //   </ul>
  // </div>
  const errorExplanationElement = document.createElement("div");
  errorExplanationElement.id = options?.id || "errorExplanation";
  errorExplanationElement.classList.add(options?.cssClass || "errorExplanation");

  const headerElement = document.createElement("h2");
  headerElement.textContent = options?.header || i18next.t("errors.template.header.one");
  errorExplanationElement.appendChild(headerElement);

  const bodyElement = document.createElement("p");
  bodyElement.textContent = options?.body || i18next.t("errors.template.body");
  errorExplanationElement.appendChild(bodyElement);

  const errorListElement = document.createElement("ul");
  errorExplanationElement.appendChild(errorListElement);
  errors.forEach((error) => {
    const errorItemElement = document.createElement("li");
    errorItemElement.textContent = error;
    errorListElement.appendChild(errorItemElement);
  });

  return errorExplanationElement;
}

export default class extends Controller {
  static values = {
    previewApi: String,
    createUrl: String,
  }
  static targets = [
    "option",
    "fileUploadShadow", "fileUploadReal", "fileUploadDropArea",
    "fileUploadWaitingForm", "fileUploadWaitingList", "fileUploadWaitingItem", "fileUploadWaitingItemTemplate" ];

  connect() {
    if (this.hasFileUploadShadowTarget) {
      this.fileUploadShadowTarget.addEventListener('change', () => this.#selectFiles())
    }
    if (this.hasFileUploadWaitingFormTarget) {
      this.fileUploadWaitingFormTarget.addEventListener('submit', (ev) => {
        ev.preventDefault();
        this.#uploadAllWaitingItems();
      })
    }
    if (this.hasFileUploadDropAreaTarget) {
      new DropArea(this.fileUploadDropAreaTarget, (files) => this.#appendFilesToWaitingList(files));
    }
    this.element.addEventListener("ss:tempFile:upload", (ev) => {
      this.#appendFilesToWaitingList(ev.detail.files)
    });
  }

  optionTargetConnected(element) {
    const option = JSON.parse(element.innerHTML);
    for (const key in option) {
      this[`${key}Value`] = option[key];
    }
  }

  openDialog() {
    if (!this.hasFileUploadShadowTarget) {
      return;
    }

    this.fileUploadShadowTarget.click();
  }

  deselect(ev) {
    if (!this.hasFileUploadWaitingItemTarget) {
      return;
    }

    let removed = false;
    this.fileUploadWaitingItemTargets.forEach((item) => {
      if (item.contains(ev.target)) {
        removed = this.fileUploadWaitingListTarget.contains(item);
        item.remove();
      }
    })

    if (removed) {
      if (this.fileUploadWaitingItemTargets.length > 0) {
        this.fileUploadWaitingFormTarget.classList.remove("hide")
      } else {
        this.fileUploadWaitingFormTarget.classList.add("hide")
      }

      dispatchEvent(this.fileUploadWaitingListTarget, "change");
    }
  }

  selectFile(ev) {
    ev.preventDefault();
    dispatchEvent(ev.target, "ss:modal-select", { item: $(ev.target) });
    dispatchEvent(ev.target, "ss:modal-close");
  }

  async deleteFile(ev) {
    const href = ev.target.dataset.href;
    if (!href) {
      return;
    }

    if (!confirm(i18next.t('ss.confirm.delete'))) {
      return false;
    }

    const params = new FormData();
    params.append("_method", "delete")

    const saveHtml = ev.target.innerHTML;
    ev.target.innerHTML = LOADING;

    const response = await fetch(href, {
      method: "POST",
      headers: { "X-CSRF-Token": csrfToken() },
      body: params
    });
    ev.target.innerHTML = saveHtml;
    if (!response.ok) {
      alert(["== Error(AjaxFile) =="]);
      return;
    }

    let targetElement;
    if (ev.target.dataset.remove) {
      targetElement = document.querySelector(ev.target.dataset.remove);
    }
    targetElement ||= ev.target.closest(".file-view");

    targetElement.classList.add("animate__animated", "animate__zoomOut", "animate__faster")
    targetElement.addEventListener('animationend', () => {
      targetElement.remove();
      dispatchEvent(this.element, "ss:ajaxRemoved");
    }, { once: true });
  }

  async #selectFiles() {
    const files = this.fileUploadShadowTarget.files;
    if (!files || files.length === 0) {
      return;
    }

    if (this.hasFileUploadRealTarget) {
      this.fileUploadRealTarget.disabled = true;
    }

    await this.#appendFilesToWaitingList(files);

    this.fileUploadShadowTarget.files = undefined;
    this.fileUploadShadowTarget.value = '';
    if (this.hasFileUploadRealTarget) {
      this.fileUploadRealTarget.disabled = false;
    }
  }

  async #appendFilesToWaitingList(files) {
    const templateSource = this.fileUploadWaitingItemTemplateTarget.innerHTML;

    const renderOne = async (file) => {
      const formData = new FormData();
      formData.append("item[files][][name]", file.name);
      formData.append("item[files][][size]", file.size);
      formData.append("item[files][][content_type]", file.type);

      const response = await fetch(this.previewApiValue, {
        method: "POST",
        headers: { "X-CSRF-Token": csrfToken() },
        body: formData
      });
      const json = await response.json();

      const html = ejs.render(templateSource, { selectedItems: json })
      prependChildren(this.fileUploadWaitingListTarget, html);
    };

    for (const file of Array.from(files).reverse()) {
      await renderOne(file);

      const newFileElement = this.fileUploadWaitingListTarget.querySelector(`[name="item[files][][in_file]"]`);
      if (newFileElement) {
        const dataTransfer = new DataTransfer();
        dataTransfer.items.add(file);
        newFileElement.files = dataTransfer.files;
      }
    }

    if (this.hasFileUploadWaitingItemTemplateTarget) {
      if (this.fileUploadWaitingItemTargets.length > 0) {
        this.fileUploadWaitingFormTarget.classList.remove("hide")
      } else {
        this.fileUploadWaitingFormTarget.classList.add("hide")
      }
    }

    dispatchEvent(this.fileUploadWaitingListTarget, "ss:tempFile:addedWaitingList");
  }

  async #uploadAllWaitingItems() {
    for(const item of this.fileUploadWaitingItemTargets) {
      const operationsElement = item.querySelector(".operations");
      if (operationsElement) {
        operationsElement.textContent = i18next.t("ss.notice.wait_to_upload");
      }
    }

    let allSucceeded = true;
    const uploadedItems = [];
    for(const item of this.fileUploadWaitingItemTargets) {
      const fileElement = item.querySelector(`[name="item[files][][in_file]"]`)
      if (! fileElement.files || fileElement.files.length === 0) {
        continue;
      }
      const file = fileElement.files[0];
      if (!file) {
        continue;
      }

      const nameElement = item.querySelector(`[name="item[files][][name]"]`);
      if (!nameElement) {
        continue;
      }

      const name = nameElement.value;

      const filename = item.querySelector(`[name="item[files][][filename]"]`)?.value;
      const resizing = item.querySelector(`[name="item[files][][resizing]"]`)?.value;
      const quality = item.querySelector(`[name="item[files][][quality]"]`)?.value;
      const imageResizesDisabled = item.querySelector(`[name="item[files][][image_resizes_disabled]"]`)?.value;

      const operationsElement = item.querySelector(".operations");
      if (operationsElement) {
        operationsElement.textContent = i18next.t("ss.notice.uploading");
      }

      const result = await this.#uploadOneFile({ item, name, filename, file, resizing, quality, imageResizesDisabled });
      if (result) {
        uploadedItems.push(item);
      } else {
        allSucceeded = false;
      }
    }

    if (allSucceeded) {
      uploadedItems.forEach((item) => {
        dispatchEvent(this.element, "ss:modal-select", { item: $(item) });
      });
      dispatchEvent(this.element, "ss:modal-close");
    }
  }

  async #uploadOneFile({ item, name, filename, resizing, quality, imageResizesDisabled, file }) {
    const createParams = new FormData();
    if (name) {
      createParams.append("item[name]", name);
    }
    if (filename) {
      createParams.append("item[filename]", filename);
    }
    if (resizing) {
      createParams.append("item[resizing]", resizing);
    }
    if (quality) {
      createParams.append("item[quality]", quality);
    }
    if (imageResizesDisabled) {
      createParams.append("item[image_resizes_disabled]", imageResizesDisabled);
    }
    createParams.append("item[in_file]", file);

    let lastResponse = undefined;
    for (let i = 0; i < NUM_RETRY; i++) {
      const createResponse = await fetch(this.createUrlValue, {
        method: "POST",
        headers: { "X-CSRF-Token": csrfToken() },
        body: createParams,
      });
      lastResponse = createResponse;
      if (createResponse.ok) {
        break;
      }
    }
    if (!lastResponse.ok) {
      try {
        const errorResult = await lastResponse.json();
        this.#showError(item, errorResult);
      } catch(_ex) {
        this.#showError(item, ["failed to upload"]);
      }
      return false;
    }

    const createResult = await lastResponse.json();

    item.dataset.id = createResult['_id'];
    item.dataset.fileId = createResult['_id'];
    item.dataset.name = createResult['name'];
    item.dataset.humanizedName = createResult['humanized_name'];
    item.dataset.extname = createResult['extname'];
    item.dataset.url = createResult['url'];
    item.dataset.image_ = createResult['image?'];
    item.dataset.thumbUrl = createResult['thumb_url'];
    item.dataset.imageDimension = createResult['image_dimension'];
    item.dataset.size = createResult['size'];
    if (createResult['updated']) {
      item.dataset.updated = moment(createResult['updated']).format("X");
    }
    if (createResult['sanitizer_state']) {
      item.dataset.sanitizerState = createResult['sanitizer_state'];
    }
    if (createResult['sanitizer_state_label']) {
      item.dataset.sanitizerStateLabel = createResult['sanitizer_state_label'];
    }
    // item.setAttribute("data-id", createResult['_id']);
    const nameElement = item.querySelector(".name");
    if (nameElement) {
      nameElement.textContent = createResult['name'];
    }
    const filenameElement = item.querySelector(".filename");
    if (filenameElement) {
      filenameElement.textContent = createResult['filename'];
    }
    const optionsElement = item.querySelector(".options");
    if (optionsElement) {
      optionsElement.innerHTML = '';
    }
    const operationsElement = item.querySelector(".operations");
    if (operationsElement) {
      operationsElement.textContent = i18next.t("ss.notice.finished_uploading");
    }
    const errorsElement = item.querySelector(".errors");
    if (errorsElement) {
      errorsElement.innerHTML = '';
      errorsElement.classList.add("hide");
    }

    return true;
  }

  #showError(item, errorMessages) {
    const operationsElement = item.querySelector(".operations");
    if (operationsElement) {
      const buttonElement = document.createElement("button")
      buttonElement.type = "button";
      buttonElement.name = "delete";
      buttonElement.value = "delete";
      buttonElement.classList.add("btn");
      buttonElement.dataset.action = "ss--temp-file#deselect";
      buttonElement.textContent = i18next.t("ss.buttons.delete");

      operationsElement.replaceChildren(buttonElement);
    }

    const errorsElement = item.querySelector(".errors");
    if (errorsElement) {
      errorsElement.replaceChildren(createError(errorMessages));
      errorsElement.classList.remove("hide");
    }
  }
}
