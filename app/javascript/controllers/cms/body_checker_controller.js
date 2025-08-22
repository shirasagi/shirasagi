import {Controller} from "@hotwired/stimulus";
import {collectFormData, dispatchEvent, LOADING, replaceChildren, replaceWith} from "../../ss/tool";
import i18next from 'i18next'

export default class extends Controller {
  static targets = [ "fieldset", "result" ]
  static values = { checkUrl: String, correctUrl: String, id: String };

  initialize() {
  }

  connect() {
    // console.log(`[${this.identifier}] connected`);
    this.element.addEventListener("ss:formAlert:run", (ev) => this.#formAlert(ev));
  }

  disconnect() {
  }

  async check(_ev) {
    // console.log(`[${this.identifier}] check`, ev);
    const formElement = this.element.closest("form");
    const formData = collectFormData(formElement);
    // 余分なデータを削除
    // formData.delete("authenticity_token");
    formData.delete("_method");
    formData.delete("_updated");
    // cms--body-checker は同一 HTML 上に cms/addon/body と cms/addon/form/page と 2 つ存在
    // 自分が管理している checks オプションのみを formData へ設定する。
    formData.delete("checks[]");
    this.element.querySelectorAll(`[name="checks[]"]`).forEach((element) => {
      if (element.checked) {
        formData.append("checks[]", element.value);
      }
    });
    if (this.hasIdValue && this.idValue && !formData.has("id")) {
      formData.append("id", this.idValue);
    }

    this.fieldsetTarget.disabled = true;
    this.resultTarget.innerHTML = LOADING;

    const response = await fetch(this.checkUrlValue, {
      method: "POST",
      body: formData
    });

    if (response.ok) {
      await this.#renderCheckResult(response);
    } else {
      await this.#renderCheckError(response);
    }

    this.fieldsetTarget.disabled = false;
    dispatchEvent(this.element, "ss:check:done")
  }

  async #renderCheckResult(response) {
    const html = await response.text();
    this.resultTarget.innerHTML = html;
  }

  async #renderCheckError(_response) {
    const message = i18next.t("errors.messages.syntax_check_server_error")
    this.resultTarget.innerHTML = `<div class="main-box">${message}</div>`;
  }

  async #formAlert(_ev) {
    // console.log(`[${this.identifier}] #formAlert`);
    const formElement = this.element.closest("form");
    const formData = collectFormData(formElement);
    // 余分なデータを削除
    // formData.delete("authenticity_token");
    formData.delete("_method");
    formData.delete("_updated");
    // form alertの場合はアクセシビリティチェックのみを実行する
    formData.delete("checks[]");
    formData.append("checks[]", "form_alert");
    if (this.hasIdValue && this.idValue && !formData.has("id")) {
      formData.append("id", this.idValue);
    }

    this.fieldsetTarget.disabled = true;

    const checkUrlValue = this.checkUrlValue.endsWith(".json") ? this.checkUrlValue : `${this.checkUrlValue}.json`;
    const response = await fetch(checkUrlValue, { method: "POST", body: formData });

    let detail;
    if (response.ok) {
      detail = await response.json();
    } else {
      const message = i18next.t("errors.messages.syntax_check_server_error");
      detail = { status: "server-error", errors: [{ msg: message }] };
    }

    this.fieldsetTarget.disabled = false;
    dispatchEvent(this.element, "ss:formAlert:done", detail);
  }

  async correct(ev) {
    // console.log(`[${this.identifier}] correct`, ev.params, this.correctUrlValue);

    const formElement = this.element.closest("form");
    const formData = collectFormData(formElement);
    // 余分なデータを削除
    // formData.delete("authenticity_token");
    formData.delete("_method");
    formData.delete("_updated");

    formData.append("corrector[param]", ev.params['param'])

    this.fieldsetTarget.disabled = true;
    this.element.querySelectorAll("[name='btn-correct']").forEach((element) => { element.disabled = true; })

    const response = await fetch(this.correctUrlValue, {
      method: "POST",
      body: formData
    });
    if (!response.ok) {
      this.element.querySelectorAll("[name='btn-correct']").forEach((element) => { element.disabled = false; })
      this.fieldsetTarget.disabled = false;
      dispatchEvent(this.element, "ss:correct:failed")
      alert(i18next.t("cms.auto_correct.failed"));
      return;
    }

    const result = await response.json();
    await this.#update(result)

    this.element.querySelectorAll("[name='btn-correct']").forEach((element) => { element.disabled = false; })
    this.fieldsetTarget.disabled = false;
    dispatchEvent(this.element, "ss:correct:done")
  }

  async #update(result) {
    if (result["check_result_html"]) {
      const tempElement = document.createElement("template");
      tempElement.innerHTML = result["check_result_html"];
      replaceChildren(
        document.getElementById("errorSyntaxChecker"),
        tempElement.content.querySelector(`[id="errorSyntaxChecker"]`).innerHTML);
    }

    const id = result["id"];
    if ("CKEDITOR" in window) {
      const editor = CKEDITOR.instances[id];
      if (editor) {
        await this.#updateCKEditor(editor, result["corrected_html"]);
      }
    }
    if ("CodeMirror" in window) {
      const editor = $(document.getElementById(result["id"])).data("editor");
      if (editor instanceof CodeMirror) {
        await this.#updateCodeMirror(editor, result["corrected_html"]);
      }
    }
    if (id.startsWith("column-value-")) {
      // console.log(`[${this.identifier}] #update`, id, result["corrected_html"]);
      const columnValueElement = document.getElementById(result["id"]);
      if (columnValueElement) {
        replaceWith(columnValueElement, result["corrected_html"]);
      }
    }
  }

  #updateCKEditor(editor, html) {
    const promise = new Promise(function (resolve, _reject) {
      editor.setData(html, { callback: () => {
          editor.checkDirty();
          editor.updateElement();
          resolve();
        }
      });
    });
    return promise;
  }

  #updateCodeMirror(editor, html) {
    editor.getDoc().setValue(html);
    return Promise.resolve();
  }
}
