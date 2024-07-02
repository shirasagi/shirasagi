import { Controller } from "@hotwired/stimulus"
import i18next from 'i18next'
import {csrfToken, dispatchEvent} from "../../ss/tool"

function formDataToStringifyJson(formData) {
  const array = [];
  for (const pair of formData.entries()) {
    array.push(pair);
  }

  return JSON.stringify(array);
}

function stringifyJsonToFormData(stringifyJson) {
  const array = JSON.parse(stringifyJson)
  const formData = new FormData();
  array.forEach((pair) => formData.append(pair[0], pair[1]));

  return formData;
}

export default class extends Controller {
  static values = { userId: String, resumeUrl: String }

  #lastAutoSaved = 0;
  #submitted = false;
  #beforeUnloadHandler = undefined;

  async connect() {
    SS.disableConfirmUnloading = true;
    this.#submitted = false;
    this.element.addEventListener("submit", () => {
      this.#submitted = true;
      this.#onUnload();
    });
    this.#beforeUnloadHandler = () => { this.#onUnload(); };
    window.addEventListener("beforeunload", this.#beforeUnloadHandler);

    const autoSaveData = localStorage.getItem(this.#key());
    if (autoSaveData && confirm(i18next.t("ss.confirm.resume_editing"))) {
      await this.#restoreForm(autoSaveData);
    }

    this.#serializeFormData();

    setInterval(() => this.#serializeFormDataIfModified(), 5000)
  }

  disconnect() {
    this.#onUnload();
    window.removeEventListener("beforeunload", this.#beforeUnloadHandler);
  }

  #key() {
    // 業務端末を複数職員で共有するケースを想定し、ユーザーIDを含める
    return `autosave.${this.userIdValue}.${location.pathname}`;
  }

  #onUnload() {
    if (this.#submitted && this.#isSessionAlive()) {
      // form を送信したので local storage の編集途中のデータを削除
      localStorage.removeItem(this.#key())
    } else {
      // form は未送信のため、編集途中のデータを local storage へ保存
      this.#serializeFormData();
    }
  }

  #serializeFormDataIfModified() {
    if (! SS.formChanged) {
      return;
    }
    if (SS.formChanged <= this.#lastAutoSaved) {
      return;
    }

    this.#serializeFormData();
  }

  #serializeFormData() {
    Object.values(CKEDITOR.instances).forEach((editor) => {
      if (!editor.checkDirty()) {
        return;
      }
      if (editor.elementMode !== CKEDITOR.ELEMENT_MODE_REPLACE) {
        return;
      }

      editor.updateElement();
      editor.resetDirty();
    });

    const formData = new FormData(this.element);
    // 余分なデータを削除
    formData.delete("authenticity_token");
    formData.delete("_method");
    formData.delete("_updated");

    localStorage.setItem(this.#key(), formDataToStringifyJson(formData))
    this.#lastAutoSaved = new Date().getTime();
  }

  async #restoreForm(stringifyData) {
    const formData = stringifyJsonToFormData(stringifyData)

    this.#disableForm();

    const response = await fetch(this.resumeUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken()
      },
      body: formData
    });
    if (!response.ok) {
      alert(i18next.t("ss.errors.failed_to_resume_editing"));
      this.#enableForm();
      this.element.dataset.ssAutoSaveState = "failed";
      dispatchEvent(this.element, "ss:restored");
      return;
    }

    const html = await response.text();

    this.#replaceItemForm(html);

    window.requestAnimationFrame(() => {
      this.#enableForm();
      this.element.dataset.ssAutoSaveState = "restored";
      dispatchEvent(this.element, "ss:restored");
    });
  }

  #disableForm() {
    this.element.disabled = true;
    this.element.querySelectorAll("input[type='submit']").forEach((inputElement) => {
      inputElement.disabled = true;
    });
    this.element.querySelectorAll("button[type='submit']").forEach((inputElement) => {
      inputElement.disabled = true;
    });
  }

  #enableForm() {
    this.element.querySelectorAll("input[type='submit']").forEach((inputElement) => {
      inputElement.disabled = false;
    });
    this.element.querySelectorAll("button[type='submit']").forEach((inputElement) => {
      inputElement.disabled = false;
    });
    this.element.disabled = false;
  }

  #replaceItemForm(html) {
    const doc = new DOMParser().parseFromString(html, "text/html");
    const itemForm = doc.querySelector("#item-form").children;

    this.element.replaceChildren(...itemForm);

    // execute pre-requisites.
    SS_DateTimePicker.render();

    // 定型フォームツールバーを再び利用できる（初期化できる）ように、グローバル変数をクリアする。
    // see app/assets/javascripts/cms/lib/template_form.js
    Cms_TemplateForm.instance = null;
    Cms_TemplateForm.userId = null;
    Cms_TemplateForm.target = null;
    Cms_TemplateForm.confirms = {};
    Cms_TemplateForm.paths = {};

    // execute javascript within item-form
    this.element.querySelectorAll("script").forEach((scriptElement) => {
      const newScriptElement = document.createElement("script")
      Array.from(scriptElement.attributes).forEach(attr => newScriptElement.setAttribute(attr.name, attr.value))
      newScriptElement.appendChild(document.createTextNode(scriptElement.innerHTML))
      scriptElement.parentElement.replaceChild(newScriptElement, scriptElement)
    })
  }

  #isSessionAlive() {
    // セッション有効時、data-ss-session 属性が存在しないか、値が "alive" になる。
    if (!document.body.hasAttribute("data-ss-session")) {
      return true;
    }

    const sessionState = document.body.getAttribute("data-ss-session");
    if (sessionState === "alive") {
      return true;
    }

    return false;
  }
}
