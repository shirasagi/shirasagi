import { Controller } from "@hotwired/stimulus"
import i18next from 'i18next'
import { csrfToken } from "../../ss/tool"

function formDataToStringifyJson(formData) {
  return JSON.stringify(Object.fromEntries(formData));
}

function stringifyJsonToFormData(stringifyJson) {
  const data = JSON.parse(stringifyJson)
  const formData = new FormData();
  for (const key in data) {
    formData.append(key, data[key])
  }

  return formData;
}

export default class extends Controller {
  static values = { resumeUrl: String }

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

    const autoSaveData = localStorage.getItem(`autosave.${location.pathname}`);
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

  #onUnload() {
    if (this.#submitted) {
      // form を送信したので local storage の編集途中のデータを削除
      localStorage.removeItem(`autosave.${location.pathname}`)
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
    const formData = new FormData(this.element);
    // 余分なデータを削除
    formData.delete("authenticity_token")
    formData.delete("_method")
    formData.delete("_updated")

    localStorage.setItem(`autosave.${location.pathname}`, formDataToStringifyJson(formData))
    this.#lastAutoSaved = new Date().getTime();
  }

  async #restoreForm(stringifyData) {
    const formData = stringifyJsonToFormData(stringifyData)

    this.element.disabled = true;

    const response = await fetch(this.resumeUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken()
      },
      body: formData
    });
    if (!response.ok) {
      alert(i18next.t("ss.errors.failed_to_resume_editing"));
      this.element.disabled = false;
      return;
    }

    // html 内には javascript が含まれており、javascript の動的実行はややこしいので jQuery を用いる。
    const html = await response.text();

    // 理想は item-form の内容の置換だが javascript のエラーが発生する。
    // $(this.element).html($(html).find("#item-form").html());

    // しかたなく body 全体を置換する（これはこれで問題がでそうだが）。
    $(document).find("body").html($(html).find("body").html());

    this.element.disabled = false;
  }
}
